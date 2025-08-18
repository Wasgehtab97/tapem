import 'package:flutter/material.dart';
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
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = widget.provider;
    final itemCount = 1 + prov.sessionSnapshots.length;
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          physics: const PageScrollPhysics(),
          itemCount: itemCount,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
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
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentIndex == 0
                ? null
                : () => _controller.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentIndex == itemCount - 1
                ? null
                : () => _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
          ),
        ),
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
        Positioned(
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
        ),
      ],
    );
  }
}
