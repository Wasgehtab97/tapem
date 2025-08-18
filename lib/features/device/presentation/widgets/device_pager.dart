import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'read_only_snapshot_page.dart';

class DevicePager extends StatefulWidget {
  final Widget editablePage;
  final DeviceProvider provider;
  final String gymId;
  final String deviceId;
  const DevicePager({
    super.key,
    required this.editablePage,
    required this.provider,
    required this.gymId,
    required this.deviceId,
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

    final pageView = PageView.builder(
      controller: _pc,
      reverse: true,
      physics: const PageScrollPhysics(),
      itemCount: itemCount,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        HapticFeedback.lightImpact();
        if (index >= itemCount - 2 && prov.hasMoreSnapshots) {
          prov.loadMoreSnapshots(
            gymId: widget.gymId,
            deviceId: widget.deviceId,
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

    return Stack(
      children: [
        pageView,
        if (prov.sessionSnapshots.isEmpty && !prov.isLoadingSnapshots)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Text(
                  'Keine Historie',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        EdgeGestureOverlay(
          enabled: isEditor,
          onLeftEdgeSwipe: _goToPreviousSession,
          onRightEdgeSwipe: _goToNextSession,
        ),
        _buildChevrons(itemCount),
        _buildBottomDate(prov),
      ],
    );
  }

  Widget _buildChevrons(int itemCount) {
    return Positioned.fill(
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Vorherige Session',
            onPressed:
                _currentIndex == itemCount - 1 ? null : _goToPreviousSession,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Neuere / Aktuelle',
            onPressed: _currentIndex == 0 ? null : _goToNextSession,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDate(DeviceProvider prov) {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Center(
        child: _currentIndex == 0
            ? const SizedBox.shrink()
            : Text(
                DateFormat('dd.MM.yyyy')
                    .format(prov.sessionSnapshots[_currentIndex - 1].createdAt),
              ),
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
