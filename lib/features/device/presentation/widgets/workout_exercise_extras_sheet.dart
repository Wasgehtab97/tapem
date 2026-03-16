import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkoutExerciseExtrasSheet extends StatelessWidget {
  const WorkoutExerciseExtrasSheet({
    super.key,
    required this.brandColor,
    required this.isBodyweightMode,
    required this.level,
    required this.xp,
    required this.hasNote,
    required this.onOpenLeaderboard,
    required this.onOpenHistory,
    required this.onToggleBodyweight,
    required this.onFeedback,
    required this.onOpenNote,
    this.isBodyweightToggleEnabled = true,
    this.bodyweightDisabledHint,
  });

  final Color brandColor;
  final bool isBodyweightMode;
  final int level;
  final int xp;
  final bool hasNote;
  final VoidCallback? onOpenLeaderboard;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onToggleBodyweight;
  final VoidCallback? onFeedback;
  final VoidCallback? onOpenNote;
  final bool isBodyweightToggleEnabled;
  final String? bodyweightDisabledHint;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width <= 390;
    final resolvedBodyweightSubtitle = isBodyweightToggleEnabled
        ? (isBodyweightMode ? 'Modus aktuell aktiv' : 'Modus aktuell inaktiv')
        : bodyweightDisabledHint ??
              (isBodyweightMode
                  ? 'Modus aktiv · nur im aktiven Workout änderbar'
                  : 'Modus inaktiv · nur im aktiven Workout änderbar');

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(10, 0, 10, isNarrow ? 10 : 12),
        padding: EdgeInsets.fromLTRB(
          isNarrow ? 13 : 16,
          12,
          isNarrow ? 13 : 16,
          isNarrow ? 16 : 18,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0D15),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withOpacity(0.24),
                  ),
                ),
              ),
              Text(
                'Übungs-Extras',
                style: GoogleFonts.inter(
                  fontSize: isNarrow ? 16 : 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Alles rund um diese Übung an einem Ort.',
                style: GoogleFonts.inter(
                  fontSize: isNarrow ? 11.5 : 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.62),
                ),
              ),
              const SizedBox(height: 14),
              WorkoutExerciseExtrasSection(
                title: 'Leistung',
                children: [
                  WorkoutExerciseExtrasActionTile(
                    icon: Icons.emoji_events_rounded,
                    title: 'Bestenliste',
                    subtitle: 'Rekorde und Top-Werte dieser Übung',
                    accent: brandColor,
                    onTap: onOpenLeaderboard,
                  ),
                  WorkoutExerciseExtrasActionTile(
                    icon: Icons.history_rounded,
                    title: 'Verlauf',
                    subtitle: 'Letzte Trainings und Fortschritt',
                    accent: brandColor,
                    onTap: onOpenHistory,
                  ),
                  WorkoutExerciseExtrasActionTile(
                    icon: Icons.military_tech_rounded,
                    title: 'Level $level',
                    subtitle: '$xp XP',
                    accent: brandColor,
                    onTap: null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              WorkoutExerciseExtrasSection(
                title: 'Kontext',
                children: [
                  WorkoutExerciseExtrasActionTile(
                    icon: Icons.accessibility_new_rounded,
                    title: 'Körpergewicht',
                    subtitle: resolvedBodyweightSubtitle,
                    accent: brandColor,
                    activeBadge: isBodyweightMode ? 'Aktiv' : null,
                    onTap: isBodyweightToggleEnabled
                        ? onToggleBodyweight
                        : null,
                  ),
                  WorkoutExerciseExtrasActionTile(
                    icon: Icons.edit_note_rounded,
                    title: 'Notiz',
                    subtitle: hasNote
                        ? 'Notiz vorhanden, zum Bearbeiten tippen'
                        : 'Kurze Technik- oder Satznotiz hinterlegen',
                    accent: brandColor,
                    activeBadge: hasNote ? 'Vorhanden' : null,
                    onTap: onOpenNote,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              WorkoutExerciseExtrasSection(
                title: 'Hilfe',
                children: [
                  WorkoutExerciseExtrasActionTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Feedback',
                    subtitle: 'Fehler melden oder Idee teilen',
                    accent: brandColor,
                    onTap: onFeedback,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutExerciseExtrasSection extends StatelessWidget {
  const WorkoutExerciseExtrasSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.25,
              color: Colors.white.withOpacity(0.56),
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class WorkoutExerciseExtrasActionTile extends StatelessWidget {
  const WorkoutExerciseExtrasActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.activeBadge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String? activeBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: enabled
                  ? Colors.white.withOpacity(0.03)
                  : Colors.white.withOpacity(0.015),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: enabled
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: enabled
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: enabled
                          ? Colors.white.withOpacity(0.8)
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: enabled
                                      ? Colors.white.withOpacity(0.92)
                                      : Colors.white.withOpacity(0.48),
                                ),
                              ),
                            ),
                            if (activeBadge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: accent.withOpacity(0.24),
                                  border: Border.all(
                                    color: accent.withOpacity(0.7),
                                  ),
                                ),
                                child: Text(
                                  activeBadge!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: enabled
                                ? Colors.white.withOpacity(0.62)
                                : Colors.white.withOpacity(0.34),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: enabled
                        ? Colors.white.withOpacity(0.44)
                        : Colors.white.withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
