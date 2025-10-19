import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'read_only_snapshot_page.dart';

class DevicePager extends StatefulWidget {
  final Widget editablePage;
  final DeviceProvider provider;
  final String gymId;
  final String deviceId;
  final String userId;
  const DevicePager({
    super.key,
    required this.editablePage,
    required this.provider,
    required this.gymId,
    required this.deviceId,
    required this.userId,
  });

  @override
  State<DevicePager> createState() => DevicePagerState();
}

class DevicePagerState extends State<DevicePager> {
  late final PageController _pc;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void animateToPage(int page) {
    _pc.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousSession() {
    _pc.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextSession() {
    _pc.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void goToPreviousSession() => _goToPreviousSession();
  void goToNextSession() => _goToNextSession();

  @override
  Widget build(BuildContext context) {
    final prov = widget.provider;
    final itemCount = 1 + prov.sessionSnapshots.length;

    if ((_currentIndex == 0 || _currentIndex == 1) &&
        prov.hasMoreSnapshots &&
        prov.sessionSnapshots.length < 20) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        prov.prefetchSnapshots(
          gymId: widget.gymId,
          deviceId: widget.deviceId,
          userId: widget.userId,
        );
      });
    }

    final pageView = PageView.builder(
      controller: _pc,
      reverse: true,
      physics: const PageScrollPhysics(),
      itemCount: itemCount,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        HapticFeedback.lightImpact();
        if (index >= itemCount - 3 && prov.hasMoreSnapshots) {
          prov.loadMoreSnapshots(
            gymId: widget.gymId,
            deviceId: widget.deviceId,
            userId: widget.userId,
          );
        }
      },
      itemBuilder: (context, index) {
        if (index == 0) return widget.editablePage;
        final snap = prov.sessionSnapshots[index - 1];
        return ReadOnlySnapshotPage(snapshot: snap);
      },
    );

    final isEditor = _pc.hasClients ? _pc.page?.round() == 0 : true;

    final current =
        _currentIndex > 0 ? prov.sessionSnapshots[_currentIndex - 1] : null;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              pageView,
              EdgeGestureOverlay(
                enabled: isEditor,
                onLeftEdgeSwipe: _goToPreviousSession,
                onRightEdgeSwipe: _goToNextSession,
              ),
            ],
          ),
        ),
        _buildNavigationBar(itemCount, current),
      ],
    );
  }

  Widget _buildNavigationBar(
    int itemCount,
    DeviceSessionSnapshot? current,
  ) {
    final theme = Theme.of(context);
    final brandColor = theme.colorScheme.primary;
    final disabledColor =
        theme.colorScheme.onSurface.withOpacity(theme.brightness == Brightness.dark ? 0.4 : 0.38);
    final disabledBackground =
        theme.colorScheme.onSurface.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.12);

    Widget buildChevron({
      required IconData icon,
      required VoidCallback? onPressed,
    }) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          foregroundColor: brandColor,
          backgroundColor: brandColor.withOpacity(0.12),
          disabledForegroundColor: disabledColor,
          disabledBackgroundColor: disabledBackground,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        tooltip: icon == Icons.chevron_left
            ? 'Vorherige Session'
            : 'Neuere / Aktuelle',
      );
    }

    final dateStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.72),
      fontWeight: FontWeight.w600,
    );

    final dateText = current == null
        ? null
        : DateFormat('dd.MM.yyyy • HH:mm').format(current.createdAt);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildChevron(
            icon: Icons.chevron_left,
            onPressed:
                _currentIndex == itemCount - 1 ? null : _goToPreviousSession,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: dateText == null
                  ? const SizedBox(height: 24)
                  : Text(
                      dateText,
                      key: ValueKey(dateText),
                      textAlign: TextAlign.center,
                      style: dateStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          buildChevron(
            icon: Icons.chevron_right,
            onPressed: _currentIndex == 0 ? null : _goToNextSession,
          ),
        ],
      ),
    );
  }
}

class EdgeGestureOverlay extends StatelessWidget {
  const EdgeGestureOverlay({
    super.key,
    required this.onLeftEdgeSwipe,
    required this.onRightEdgeSwipe,
    required this.enabled,
  });

  final VoidCallback onLeftEdgeSwipe;
  final VoidCallback onRightEdgeSwipe;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        const edge = 28.0;
        return IgnorePointer(
          ignoring: false,
          child: Row(
            children: [
              SizedBox(
                width: edge,
                height: double.infinity,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 250) {
                      onLeftEdgeSwipe();
                    }
                  },
                ),
              ),
              const Expanded(child: SizedBox()),
              SizedBox(
                width: edge,
                height: double.infinity,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! < -250) {
                      onRightEdgeSwipe();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
