import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/utils/remote_url_utils.dart';

void main() {
  group('remote_url_utils', () {
    test('normalizeRemoteUrl trims and encodes spaces', () {
      expect(
        normalizeRemoteUrl('  https://example.com/my image.png  '),
        'https://example.com/my%20image.png',
      );
    });

    test('parseHttpUri returns null for empty and invalid inputs', () {
      expect(parseHttpUri(''), isNull);
      expect(parseHttpUri('example.com/path'), isNull);
      expect(parseHttpUri('ftp://example.com/file.png'), isNull);
      expect(parseHttpUri('https:///missing-host.png'), isNull);
    });

    test('parseHttpUri accepts valid http and https urls', () {
      expect(parseHttpUri('http://example.com/logo.png'), isNotNull);
      expect(parseHttpUri('https://example.com/logo.png'), isNotNull);
    });

    test('isValidHttpUrl delegates to parser', () {
      expect(isValidHttpUrl('https://example.com'), isTrue);
      expect(isValidHttpUrl('not-a-url'), isFalse);
    });
  });
}
