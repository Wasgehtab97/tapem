import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

import 'domain/session_story_data.dart';

class StoryLinkBuilder {
  final FirebaseDynamicLinks _links;
  final String? _uriPrefix;
  final String _androidPackage;
  final String _iosBundleId;

  StoryLinkBuilder({FirebaseDynamicLinks? links})
      : _links = links ?? FirebaseDynamicLinks.instance,
        _uriPrefix = dotenv.env['STORYCARD_DYNAMIC_LINK_PREFIX'],
        _androidPackage =
            dotenv.env['ANDROID_PACKAGE_NAME'] ?? 'com.example.tapem',
        _iosBundleId = dotenv.env['IOS_BUNDLE_ID'] ?? 'com.example.tapem';

  Future<Uri?> build(SessionStoryData story) async {
    if (_uriPrefix == null || _uriPrefix!.isEmpty) {
      return null;
    }
    final fallbackLink = Uri.parse('https://tapem.app/session/${story.sessionId}');
    final dateLabel = DateFormat.yMMMMd().format(story.occurredAt);
    final params = DynamicLinkParameters(
      link: fallbackLink,
      uriPrefix: _uriPrefix!,
      androidParameters: AndroidParameters(packageName: _androidPackage),
      iosParameters: IOSParameters(bundleId: _iosBundleId),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Tapem Session $dateLabel',
        description: 'Meine Story mit ${story.xpTotal.toStringAsFixed(0)} XP.',
      ),
    );
    try {
      final result = await _links.buildShortLink(params);
      return result.shortUrl;
    } catch (_) {
      return null;
    }
  }
}
