import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/core/app_result.dart';

void main() {
  test('map transforms a success value', () {
    const result = AppResult<int>.success(2);
    final mapped = result.map((value) => value * 3);

    expect(mapped, isA<AppSuccess<int>>());
    expect((mapped as AppSuccess<int>).value, 6);
  });

  test('map preserves a failure', () {
    const result = AppResult<int>.failure('No connection');
    final mapped = result.map((value) => '$value');

    expect(mapped, isA<AppFailure<String>>());
    expect((mapped as AppFailure<String>).message, 'No connection');
  });
}
