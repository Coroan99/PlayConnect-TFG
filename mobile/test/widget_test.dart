import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playconnect_mobile/src/app/app.dart';
import 'package:playconnect_mobile/src/core/storage/session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders the login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const PlayConnectApp(),
      ),
    );

    await tester.pump();

    expect(find.text('PlayConnect'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}
