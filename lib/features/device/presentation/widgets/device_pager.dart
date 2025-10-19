import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
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
            fit: StackFit.expand,
            children: [
              pageView,
              EdgeGestureOverlay(
                enabled: isEditor,
                onLeftEdgeSwipe: _goToPreviousSession,
                onRightEdgeSwipe: _goToNextSession,
              ),
              _buildBottomDateOrDots(current),
            ],
          ),
        ),
        _buildChevronRow(itemCount),
      ],
    );
  }

  Widget _buildChevronRow(int itemCount) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final accent = brand?.outline ?? theme.colorScheme.primary;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ChevronButton(
            icon: Icons.chevron_left,
            color: accent,
            tooltip: 'Vorherige Session',
            onPressed:
                _currentIndex == itemCount - 1 ? null : _goToPreviousSession,
          ),
          _ChevronButton(
            icon: Icons.chevron_right,
            color: accent,
            tooltip: 'Neuere / Aktuelle',
            onPressed: _currentIndex == 0 ? null : _goToNextSession,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDateOrDots(DeviceSessionSnapshot? current) {
    if (current == null) return const SizedBox.shrink();
    final date =
        DateFormat('dd.MM.yyyy • HH:mm').format(current.createdAt);
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(date, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
        foregroundColor: color,
        backgroundColor: color.withOpacity(0.12),
        disabledForegroundColor: color.withOpacity(0.35),
        disabledBackgroundColor: color.withOpacity(0.06),
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
