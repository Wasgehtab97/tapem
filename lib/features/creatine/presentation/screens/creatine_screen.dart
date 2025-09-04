import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar_popup.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/creatine_provider.dart';
import '../../data/creatine_repository.dart';

class CreatineScreen extends StatefulWidget {
  final String? userId;
  const CreatineScreen({super.key, this.userId});

  @override
  State<CreatineScreen> createState() => _CreatineScreenState();
}

class _CreatineScreenState extends State<CreatineScreen> {
  String _uid = '';

  Future<void> _openCalendar(CreatineProvider prov) async {
    elogUi('creatine_open_popup', {});
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CalendarPopup(
        trainingDates: prov.intakeDates.toList(),
        initialYear: DateTime.now().year,
        userId: _uid,
        navigateOnTap: false,
      ),
    );
    if (selected != null && isTodayOrYesterday(selected)) {
      prov.setSelectedDate(selected);
    }
  }

  Future<void> _openCreatineLink() async {
    final url = Uri.parse('https://www.ruehl24.de/de/aminosaeuren-creatin/creatin/');
    elogUi('creatine_link_click', {'url': url.toString()});
    final loc = AppLocalizations.of(context)!;
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.creatineOpenLinkError)));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loc = AppLocalizations.of(context)!;
      try {
        _uid = (widget.userId?.trim().isNotEmpty == true)
            ? widget.userId!.trim()
            : currentUidOrFail();
        final settingsProv = context.read<SettingsProvider>();
        await settingsProv.load(_uid);
        if (!settingsProv.creatineEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.settingsCreatineSavedDisabled)),
          );
          Navigator.pop(context);
          return;
        }
        context
            .read<CreatineProvider>()
            .loadIntakeDates(_uid, DateTime.now().year);
        elogUi('creatine_open_screen', {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorPrefix}: $e')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CreatineProvider>();
    final loc = AppLocalizations.of(context)!;
    final year = DateTime.now().year;
    final selected = prov.selectedDate;
    final dateKey = prov.selectedDateKey;
    final isTaken = prov.intakeDates.contains(dateKey);
    final formatted = DateFormat('dd.MM.yyyy').format(selected);
    final isToday = atStartOfLocalDay(selected)
        .isAtSameMomentAs(atStartOfLocalDay(nowLocal()));
    final isYesterday = atStartOfLocalDay(selected)
        .isAtSameMomentAs(atStartOfLocalDay(nowLocal()).subtract(const Duration(days: 1)));
    String label = '';
    if (isTaken) {
      label = loc.creatineRemoveMarking;
    } else if (isToday) {
      label = loc.creatineTakenToday;
    } else if (isYesterday) {
      label = loc.creatineTakenYesterday;
    }
    final canToggle = prov.canToggle;
    final buttonEnabled = canToggle && !prov.busy && _uid.isNotEmpty;

    Widget body;
    if (prov.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (prov.error != null) {
      body = Center(child: Text('${loc.errorPrefix}: ${prov.error}'));
    } else {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _openCalendar(prov),
                child: Calendar(
                  trainingDates: prov.intakeDates.toList(),
                  showNavigation: false,
                  year: year,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openCreatineLink,
                child: Text(loc.creatineNoCreatine),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (canToggle)
              ElevatedButton.icon(
                onPressed: buttonEnabled
                    ? () async {
                        try {
                          final added = await prov.toggleIntake(_uid);
                          final snack = added
                              ? loc.creatineSaved(formatted)
                              : loc.creatineRemoved(formatted);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(snack)));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${loc.errorPrefix}: $e')),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.check),
                label: Text(label),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.creatineTitle)),
      body: body,
    );
  }
}
