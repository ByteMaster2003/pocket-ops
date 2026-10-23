import 'package:flutter_test/flutter_test.dart';
import 'package:pocketops/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('PocketOps app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PocketOpsApp(isMpinSet: false));
    expect(find.text('Set Up Security MPIN'), findsOneWidget);
  });
}
