import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import '../../../../app_router.dart';

class DynamicLinkListener extends StatefulWidget {
  final Widget child;

  /// Optional override hooks used by tests to control dynamic link delivery.
  final Future<PendingDynamicLinkData?> Function()? getInitialLink;
  final Stream<PendingDynamicLinkData>? onLinkStream;

  const DynamicLinkListener({
    required this.child,
    Key? key,
    this.getInitialLink,
    this.onLinkStream,
  }) : super(key: key);

  @override
  State<DynamicLinkListener> createState() => _DynamicLinkListenerState();
}

class _DynamicLinkListenerState extends State<DynamicLinkListener> {
  StreamSubscription<PendingDynamicLinkData>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initLinks();
  }

  Future<void> _initLinks() async {
    final links = FirebaseDynamicLinks.instance;
    final initial = await (widget.getInitialLink ?? () => links.getInitialLink())();
    if (initial != null) _handleLink(initial);
    final stream = widget.onLinkStream ?? links.onLink;
    _linkSubscription = stream.listen(_handleLink);
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
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
