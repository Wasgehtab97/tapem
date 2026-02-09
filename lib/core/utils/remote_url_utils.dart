String normalizeRemoteUrl(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '';
  }
  return trimmed.replaceAll(' ', '%20');
}

Uri? parseHttpUri(String? value) {
  final normalized = normalizeRemoteUrl(value);
  if (normalized.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    return null;
  }
  if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  if (uri.host.isEmpty) {
    return null;
  }
  return uri;
}

bool isValidHttpUrl(String? value) => parseHttpUri(value) != null;
