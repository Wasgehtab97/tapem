import 'package:flutter/painting.dart';

bool isBenignNetworkImageError(Object error) {
  if (error is NetworkImageLoadException) {
    return true;
  }

  final message = error.toString().toLowerCase();
  return message.contains('networkimage') &&
      message.contains('http request failed');
}
