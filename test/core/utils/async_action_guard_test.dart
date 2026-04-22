import 'dart:async';

import 'package:controle_instrumentos/core/utils/async_action_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns action result and resets running flag', () async {
    final guard = AsyncActionGuard();

    final result = await guard.run(() async => 42);

    expect(result, 42);
    expect(guard.isRunning, isFalse);
  });

  test('blocks concurrent run calls while one is in progress', () async {
    final guard = AsyncActionGuard();
    final completer = Completer<int>();

    final first = guard.run(() async => completer.future);
    final second = await guard.run(() async => 99);

    expect(second, isNull);
    expect(guard.isRunning, isTrue);

    completer.complete(1);
    final firstResult = await first;

    expect(firstResult, 1);
    expect(guard.isRunning, isFalse);
  });
}
