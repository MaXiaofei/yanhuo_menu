import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../services/dish_service.dart';
import '../../services/upload_service.dart';

/// 录入新菜页 — 两种模式：
/// 1. 手动录入：封面图 + 菜名 + 时间/难度 + 步骤（图文）
/// 2. 链接导入：粘贴下厨房/美食杰/豆果链接，后端 Jsoup 解析落库
class CreateDishPage extends StatefulWidget {
  const CreateDishPage({super.key});

  @override
  State<CreateDishPage> createState() => _CreateDishPageState();
}

class _StepData {
  final TextEditingController textCtrl;
  File? imageFile; // 压缩后的本地临时文件
  String? imageUrl; // 上传后的服务端 URL

  _StepData({String text = ''}) : textCtrl = TextEditingController(text: text);

  void dispose() {
    textCtrl.dispose();
    _cleanFile();
  }

  void _cleanFile() {
    try {
      if (imageFile != null && imageFile!.existsSync()) imageFile!.deleteSync();
    } catch (_) {}
  }
}

class _CreateDishPageState extends State<CreateDishPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // --- 手动录入表单 ---
  final _nameCtrl = TextEditingController();
  final _prepCtrl = TextEditingController();
  final _cookCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int _difficulty = 3;
  File? _coverFile; // 压缩后的封面临时文件
  String? _coverUrl; // 上传后的服务端 URL
  final List<_StepData> _steps = [];

  // --- 链接导入 ---
  final _urlCtrl = TextEditingController();

  bool _saving = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _prepCtrl.dispose();
    _cookCtrl.dispose();
    _noteCtrl.dispose();
    _priceCtrl.dispose();
    _urlCtrl.dispose();
    _cleanCoverFile();
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  void _cleanCoverFile() {
    try {
      if (_coverFile != null && _coverFile!.existsSync()) {
        _coverFile!.deleteSync();
      }
    } catch (_) {}
  }

  // ========== 图片选择 + 压缩 ==========

  Future<File?> _pickAndCompress() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // 先拿原图，后面我们自己压缩
    );
    if (xfile == null) return null;

    final original = File(xfile.path);
    try {
      final compressed = await UploadService.compress(original);
      // 删原图
      try {
        if (original.existsSync()) original.deleteSync();
      } catch (_) {}
      return compressed;
    } catch (_) {
      // 压缩失败：直接返回原图兜底，保留原图
      return original;
    }
  }

  Future<void> _onPickCover() async {
    final f = await _pickAndCompress();
    if (f == null) return;
    setState(() {
      _cleanCoverFile();
      _coverFile = f;
      _coverUrl = null; // 换了新图，重置上传状态
    });
  }

  void _onRemoveCover() {
    setState(() {
      _cleanCoverFile();
      _coverFile = null;
      _coverUrl = null;
    });
  }

  Future<void> _onPickStepImage(_StepData step) async {
    final f = await _pickAndCompress();
    if (f == null) return;
    setState(() {
      step.imageFile = f;
      step.imageUrl = null;
    });
  }

  void _onRemoveStepImage(_StepData step) {
    setState(() {
      try {
        if (step.imageFile != null && step.imageFile!.existsSync()) {
          step.imageFile!.deleteSync();
        }
      } catch (_) {}
      step.imageFile = null;
      step.imageUrl = null;
    });
  }

  // ========== 步骤管理 ==========

  void _addStep() {
    setState(() => _steps.add(_StepData()));
  }

  void _removeStep(int i) {
    setState(() {
      _steps[i].dispose();
      _steps.removeAt(i);
    });
  }

  // ========== 上传（封面 + 步骤图） ==========

  Future<void> _uploadImages() async {
    // 上传封面
    if (_coverFile != null && _coverUrl == null) {
      final result = await UploadService.uploadOne(_coverFile!);
      setState(() => _coverUrl = result.url);
    }
    // 上传步骤图
    for (final step in _steps) {
      if (step.imageFile != null && step.imageUrl == null) {
        final result = await UploadService.uploadOne(step.imageFile!);
        setState(() => step.imageUrl = result.url);
      }
    }
  }

  // ========== 保存 ==========

  Future<void> _onSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('请输入菜名');
      return;
    }

    setState(() => _saving = true);
    try {
      // 先上传所有图片
      await _uploadImages();

      // 组装 payload（对齐后端 DishSaveDTO）
      final dish = <String, dynamic>{
        'name': name,
        if (_coverUrl != null) 'coverUrl': _coverUrl,
        if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
        'prepTime':
            _prepCtrl.text.trim().isNotEmpty ? int.tryParse(_prepCtrl.text.trim()) : null,
        'cookTime':
            _cookCtrl.text.trim().isNotEmpty ? int.tryParse(_cookCtrl.text.trim()) : null,
        'difficulty': _difficulty,
        if (_priceCtrl.text.trim().isNotEmpty)
          'price': double.tryParse(_priceCtrl.text.trim()),
      };

      final validSteps = <_StepData>[];
      for (final s in _steps) {
        if (s.textCtrl.text.trim().isNotEmpty) validSteps.add(s);
      }

      final stepsJson = validSteps.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        return {
          'seq': i + 1,
          'text': s.textCtrl.text.trim(),
          'sortOrder': i + 1,
          if (s.imageUrl != null) 'images': s.imageUrl,
        };
      }).toList();

      final payload = {
        'dish': dish,
        'steps': stepsJson,
      };

      final newId = await DishService.saveDish(payload);
      _showSnack('已保存');
      // 跳转到新菜品详情
      if (mounted) {
        context.go('/dish/$newId');
      }
    } catch (e) {
      _showSnack('保存失败: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ========== URL 导入 ==========

  Future<void> _onImportUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      _showSnack('请粘贴菜谱链接');
      return;
    }
    // 简单校验
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _showSnack('链接格式不正确');
      return;
    }

    setState(() => _importing = true);
    try {
      final newId = await DishService.importDishByUrl(url);
      _showSnack('导入成功');
      if (mounted) {
        context.go('/dish/$newId');
      }
    } catch (e) {
      _showSnack('导入失败: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录入新菜'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '手动录入'),
            Tab(text: '链接导入'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildManualEntry(),
          _buildUrlImport(),
        ],
      ),
      bottomNavigationBar: _tabCtrl.index == 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _onSave,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('保存', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ========== 手动录入 Tab ==========

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCoverImage(),
          const SizedBox(height: 20),
          _buildNameField(),
          const SizedBox(height: 16),
          _buildTimeRow(),
          const SizedBox(height: 16),
          _buildDifficultySelector(),
          const SizedBox(height: 16),
          _buildPriceField(),
          const SizedBox(height: 16),
          _buildNoteField(),
          const SizedBox(height: 24),
          _buildSectionDivider('做法步骤'),
          const SizedBox(height: 12),
          ..._steps.asMap().entries.map((e) => _buildStepCard(e.key, e.value)),
          const SizedBox(height: 8),
          _buildAddStepButton(),
          const SizedBox(height: 16),
          if (_steps.isNotEmpty)
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _onSave,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('保存', style: TextStyle(fontSize: 16)),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    return GestureDetector(
      onTap: _coverFile == null ? _onPickCover : null,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E8),
          borderRadius: BorderRadius.circular(12),
          border: _coverFile == null
              ? Border.all(color: const Color(0xFFDDD5C8), style: BorderStyle.solid, width: 1.5)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: _coverFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_coverFile!, fit: BoxFit.cover),
                  // 半透明遮罩 + 操作按钮
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black54,
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _coverActionChip(
                            Icons.refresh,
                            '更换',
                            _onPickCover,
                          ),
                          const SizedBox(width: 16),
                          _coverActionChip(
                            Icons.delete_outline,
                            '删除',
                            _onRemoveCover,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 40, color: Colors.brown.shade300),
                  const SizedBox(height: 8),
                  Text(
                    '添加封面图',
                    style: TextStyle(
                      color: Colors.brown.shade300,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _coverActionChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(230),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameCtrl,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: '菜名',
        hintText: '如：番茄炒蛋',
        prefixIcon: const Icon(Icons.restaurant_menu_outlined),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTimeRow() {
    return Row(
      children: [
        Expanded(
          child: _numberField(
            _prepCtrl,
            '备料(分)',
            Icons.kitchen_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _numberField(
            _cookCtrl,
            '烹饪(分)',
            Icons.local_fire_department_outlined,
          ),
        ),
      ],
    );
  }

  Widget _numberField(
      TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('难度',
            style: TextStyle(fontSize: 14, color: AppColors.textHint)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final active = i < _difficulty;
            return GestureDetector(
              onTap: () => setState(() => _difficulty = i + 1),
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? AppColors.primary.withAlpha(30)
                      : const Color(0xFFF0F0F0),
                  border: Border.all(
                    color:
                        active ? AppColors.primary : const Color(0xFFE0E0E0),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  size: 20,
                  color: active ? AppColors.primary : const Color(0xFFCCCCCC),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return TextField(
      controller: _priceCtrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: '参考价格（元）',
        hintText: '可选',
        prefixIcon: const Icon(Icons.attach_money_outlined),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteCtrl,
      maxLines: 2,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: '备注',
        hintText: '可选，如：家常做法、少油版',
        prefixIcon: const Icon(Icons.notes_outlined),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2A26),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(int index, _StepData step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：步骤编号 + 删除
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '步骤 ${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2A26),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _removeStep(index),
                  child: const Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 描述
            TextField(
              controller: step.textCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '描述这一步怎么做…',
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            // 步骤图
            _buildStepImage(step),
          ],
        ),
      ),
    );
  }

  Widget _buildStepImage(_StepData step) {
    if (step.imageFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              step.imageFile!,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _onRemoveStepImage(step),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: () => _onPickStepImage(step),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFDDDDDD),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              '添加图片（可选）',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStepButton() {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: _addStep,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('添加步骤'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: AppColors.primary.withAlpha(100),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ========== 链接导入 Tab ==========

  Widget _buildUrlImport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // 说明卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF8F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0E0C0)),
            ),
            child: Column(
              children: [
                Icon(Icons.download_for_offline_outlined,
                    size: 48, color: AppColors.primary.withAlpha(200)),
                const SizedBox(height: 12),
                const Text(
                  '从其他 App 导入菜谱',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2A26),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '粘贴下厨房、美食杰、豆果的菜谱链接，\n自动解析菜名、步骤和图片',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // 支持的平台标签
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _platformChip('下厨房'),
                    _platformChip('美食杰'),
                    _platformChip('豆果美食'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // URL 输入
          TextField(
            controller: _urlCtrl,
            style: const TextStyle(fontSize: 15),
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: '粘贴菜谱链接…',
              prefixIcon: const Icon(Icons.link),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              suffixIcon: _urlCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _urlCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // 导入按钮
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _importing ? null : _onImportUrl,
              icon: _importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_download_outlined),
              label: Text(
                  _importing ? '正在解析菜谱…' : '开始导入',
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _platformChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8D8B8)),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFFB8956A),
        ),
      ),
    );
  }
}
