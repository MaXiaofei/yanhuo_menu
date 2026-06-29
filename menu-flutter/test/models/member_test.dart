import 'package:flutter_test/flutter_test.dart';
import 'package:menu_flutter/models/member.dart';

/// Member.fromJson：id 必填、name 缺省兜底空串。
void main() {
  group('Member.fromJson', () {
    test('完整字段', () {
      final m = Member.fromJson({'id': 1, 'name': '张爸爸'});
      expect(m.id, 1);
      expect(m.name, '张爸爸');
    });

    test('name 缺省兜底空串', () {
      final m = Member.fromJson({'id': 2});
      expect(m.id, 2);
      expect(m.name, '');
    });
  });
}
