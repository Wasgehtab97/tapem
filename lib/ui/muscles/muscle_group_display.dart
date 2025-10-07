import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';

/// Returns `true` if the group's name matches its region identifier.
bool isCanonicalMuscleGroupName(MuscleGroup group) {
  return group.name.trim().toLowerCase() == group.region.name.toLowerCase();
}

/// Localized fallback name for a [MuscleRegion].
String fallbackLabelForRegion(MuscleRegion region) {
  switch (region) {
    case MuscleRegion.brust:
      return 'Brust';
    case MuscleRegion.schulter:
      return 'Schulter';
    case MuscleRegion.nacken:
      return 'Nacken';
    case MuscleRegion.ruecken:
      return 'Rücken';
    case MuscleRegion.bizeps:
      return 'Bizeps';
    case MuscleRegion.trizeps:
      return 'Trizeps';
    case MuscleRegion.bauch:
      return 'Bauch';
    case MuscleRegion.quadrizeps:
      return 'Quadrizeps';
    case MuscleRegion.hamstrings:
      return 'Hamstrings';
    case MuscleRegion.gluteus:
      return 'Gluteus';
    case MuscleRegion.waden:
      return 'Waden';
  }
}

/// Synonyms that should map back to the fallback label for the region.
const Map<MuscleRegion, Set<String>> _fallbackAliases = {
  MuscleRegion.bauch: {
    'abs',
    'abdominals',
    'abdominal',
    'core',
    'stomach',
    'wrist flexors',
  },
};

/// Returns the best display name for a muscle group, falling back to the
/// localized region label when the stored name is canonical, empty or matches a
/// known alias.
String displayNameForMuscleGroup(MuscleRegion region, MuscleGroup? group) {
  final fallback = fallbackLabelForRegion(region);
  if (group == null) {
    return fallback;
  }
  final raw = group.name.trim();
  if (raw.isEmpty) {
    return fallback;
  }
  if (isCanonicalMuscleGroupName(group)) {
    return fallback;
  }
  final normalized = raw.toLowerCase();
  final aliases = _fallbackAliases[region];
  if (aliases != null && aliases.contains(normalized)) {
    return fallback;
  }
  return raw;
}
