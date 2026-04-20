import 'package:controle_instrumentos/core/utils/debouncer.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runs only the last scheduled action after delay', () {
    fakeAsync((async) {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
      var counter = 0;

      debouncer.run(() => counter++);
      async.elapse(const Duration(milliseconds: 200));
      debouncer.run(() => counter++);

      expect(counter, 0);

      async.elapse(const Duration(milliseconds: 299));
      expect(counter, 0);

      async.elapse(const Duration(milliseconds: 1));
      expect(counter, 1);
    });
  });

  test('dispose cancels pending action', () {
    fakeAsync((async) {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
      var called = false;

      debouncer.run(() => called = true);
      debouncer.dispose();
      async.elapse(const Duration(seconds: 1));

      expect(called, isFalse);
    });
  });
}
