import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/dish.dart';
import '../../models/nutrition_metric.dart';
import '../../services/dish_service.dart';
import '../../stores/member_store.dart';
import '../../widgets/loading_empty.dart';
import '../../widgets/nutrition_grid.dart';

/// 菜品详情（复刻 menu-mini/src/pages/dish/Detail.vue）。
/// 封面 + 营养区 + 做法步骤（**步骤计时器**）+ 标记做过/去点评。
class DishDetailPage extends StatefulWidget {
  final int id;
  const DishDetailPage({super.key, required this.id});
  @override
  State<DishDetailPage> createState() => _DishDetailPageState();
}

class _DishDetailPageState extends State<DishDetailPage> {
  DishDetail? _detail;
  List<NutritionMetric> _metrics = [];
  Map<String, num> _nutrition = {};
  final int _serving = 1;
  bool _loading = true;

  int _activeStep = -1; // 当前计时的步骤下标，-1 表示无
  int _elapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _detail = await DishService.detail(widget.id);
    } catch (_) {
      // 详情失败页面显示错误态
    }
    // 营养 + 字典并行，失败不阻断详情展示
    try {
      _nutrition = await DishService.nutrition(widget.id, serving: _serving);
    } catch (_) {}
    try {
      _metrics = await DishService.metrics();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  /// 计时器：同一时刻只激活一个步骤；再次点击当前步骤则停止。
  void _toggleTimer(int i) {
    if (_activeStep == i && _timer != null) {
      _timer!.cancel();
      _timer = null;
      setState(() => _activeStep = -1);
      return;
    }
    _timer?.cancel();
    setState(() {
      _activeStep = i;
      _elapsed = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
    });
  }

  /// 图片地址：相对路径补 baseURL，http 直返（对应 Detail.vue imgUrl）。
  String _imgUrl(String u) =>
      u.isEmpty ? '' : (u.startsWith('http') ? u : '${AppConstants.baseUrl}$u');

  Future<void> _markDone() async {
    final memberId = context.read<MemberStore>().currentId;
    if (memberId == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先选择就餐成员')));
      return;
    }
    try {
      await DishService.markDone(widget.id, memberId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已记录')));
      }
    } catch (_) {
      // 错误 toast 由拦截器处理
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('菜品详情')),
        body: _loading
            ? const LoadingView()
            : _detail == null
                ? const EmptyView(text: '加载详情失败')
                : ListView(
                    children: [
                      if (_detail!.dish.coverUrl != null &&
                          _detail!.dish.coverUrl!.isNotEmpty)
                        Image.network(
                          _imgUrl(_detail!.dish.coverUrl!),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_detail!.dish.name,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              '备料 ${_detail!.dish.prepTime ?? 0}分 · 烹饪 ${_detail!.dish.cookTime ?? 0}分 · 难度 ${_detail!.dish.difficulty ?? '-'}/5',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if ((_detail!.dish.note ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(_detail!.dish.note!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHint)),
                            ],
                          ],
                        ),
                      ),
                      if (_metrics.isNotEmpty && _nutrition.isNotEmpty) ...[
                        _SectionTitle('营养（份数 $_serving）'),
                        NutritionGrid(metrics: _metrics, values: _nutrition),
                      ],
                      const _SectionTitle('做法'),
                      ..._detail!.steps.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        final active = _activeStep == i;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      color: AppColors.divider))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('步骤 ${i + 1}'),
                                  const Spacer(),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: active
                                          ? AppColors.warnRed
                                          : AppColors.primary,
                                      minimumSize: const Size(64, 32),
                                    ),
                                    onPressed: () => _toggleTimer(i),
                                    child: Text(active ? '停止' : '计时'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(s.text),
                              if (s.imageList.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: s.imageList
                                      .map((img) => Image.network(
                                            _imgUrl(img),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox.shrink(),
                                          ))
                                      .toList(),
                                ),
                              ],
                              if (active) ...[
                                const SizedBox(height: 8),
                                Text('⏱ ${_elapsed}s',
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warnOrange),
                              onPressed: _markDone,
                              child: const Text('标记做过'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  context.push('/dish/${widget.id}/review'),
                              child: const Text('去点评'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
}
