import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nerima_gomi/app.dart';

void main() {
  testWidgets('NerimaGomiApp renders main navigation tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: NerimaGomiApp()));
    await tester.pumpAndSettle();

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('캘린더'), findsOneWidget);
    expect(find.text('분리배출 사전'), findsOneWidget);
    expect(find.text('안내 · 설정'), findsOneWidget);
  });
}
