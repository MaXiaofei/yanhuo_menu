import 'package:flutter_test/flutter_test.dart';

import 'package:menu_flutter/core/theme.dart';

void main() {
  test('smoke: 主题可构建且关键色已定义', () {
    final theme = buildAppTheme();
    expect(theme, isNotNull);
    expect(AppColors.primary, isNotNull);
    expect(AppColors.saveGreen, isNotNull);
  });
}
