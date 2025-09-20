export function parseBooleanFlag(value: string | undefined, defaultValue = false): boolean {
  if (value === undefined) {
    return defaultValue;
  }

  const normalized = value.trim().toLowerCase();
  if (normalized.length === 0) {
    return defaultValue;
  }

  if (['1', 'true', 'yes', 'on'].includes(normalized)) {
    return true;
  }

  if (['0', 'false', 'no', 'off'].includes(normalized)) {
    return false;
  }

  return defaultValue;
}

export function isDevPreviewRoleSwitchesEnabled(): boolean {
  return parseBooleanFlag(process.env.DEV_PREVIEW_ROLE_SWITCHES, false);
}
