import 'package:flutter_test/flutter_test.dart';
import 'package:menu_flutter/models/page.dart';
import 'package:menu_flutter/models/member.dart';

/// PageData.fromJson：records 非 List 时返回空、total/current/size 默认兜底。
/// 用 Member 作泛型 T 验证 fromJsonT 回调被正确调用。
Member memberFromJson(Map<String, dynamic> j) => Member.fromJson(j);

void main() {
  group('PageData.fromJson', () {
    test('正常分页：records 映射、total/current/size 透传', () {
      final p = PageData.fromJson({
        'records': [
          {'id': 1, 'name': '张爸爸'},
          {'id': 2, 'name': '张妈妈'},
        ],
        'total': 2,
        'current': 1,
        'size': 10,
      }, memberFromJson);

      expect(p.records.length, 2);
      expect(p.records[0].id, 1);
      expect(p.records[0].name, '张爸爸');
      expect(p.records[1].name, '张妈妈');
      expect(p.total, 2);
      expect(p.current, 1);
      expect(p.size, 10);
    });

    test('records 非 List（如 null）时返回空数组', () {
      final p = PageData.fromJson({'records': null}, memberFromJson);
      expect(p.records, isEmpty);
    });

    test('records 字段缺失时返回空数组', () {
      final p = PageData.fromJson({}, memberFromJson);
      expect(p.records, isEmpty);
    });

    test('total/current/size 缺省时走默认值', () {
      final p = PageData.fromJson({'records': <Map<String, dynamic>>[]}, memberFromJson);
      expect(p.total, 0);
      expect(p.current, 1);
      expect(p.size, 20);
    });

    test('num 类型的 total/current/size 能正确转 int', () {
      final p = PageData.fromJson({
        'records': <Map<String, dynamic>>[],
        'total': 5.0,
        'current': 2.0,
        'size': 20.0,
      }, memberFromJson);
      expect(p.total, 5);
      expect(p.current, 2);
      expect(p.size, 20);
    });
  });
}
