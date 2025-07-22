import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import '../../../../app_router.dart';

class DynamicLinkListener extends StatefulWidget {
  final Widget child;
  const DynamicLinkListener({required this.child, Key? key}) : super(key: key);

  @override
  State<DynamicLinkListener> createState() => _DynamicLinkListenerState();
}

class _DynamicLinkListenerState extends State<DynamicLinkListener> {
  @override
  void initState() {
    super.initState();
    _initLinks();
  }

  Future<void> _initLinks() async {
    final initial = await FirebaseDynamicLinks.instance.getInitialLink();
    if (initial != null) _handleLink(initial);
    FirebaseDynamicLinks.instance.onLink.listen(_handleLink);
  }

  void _handleLink(PendingDynamicLinkData data) {
    final params = data.link.queryParameters;
    final mode = params['mode'];
    final code = params['oobCode'];
    if (mode == 'resetPassword' && code != null) {
      Navigator.of(context).pushNamed(AppRouter.resetPassword, arguments: code);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
