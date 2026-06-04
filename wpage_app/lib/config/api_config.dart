import 'dart:io';

import 'package:flutter/foundation.dart';

/// Backend API base URL.
/// Release builds use Railway; debug builds use local uvicorn.
class ApiConfig {
  static const productionUrl =
      'https://wpagebackend-production.up.railway.app';

  static String get baseUrl {
    if (kReleaseMode) {
      return productionUrl;
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}

/// Layman-friendly labels for section types shown in the UI.
class SectionLabels {
  static const purposes = [
    'Personal Profile',
    'Business Page',
    'Job Seeker / Resume',
    'Student Profile',
    'Service Provider',
    'Trader / Shop',
    'Professional / Consultant',
  ];

  static String forType(String type) {
    switch (type) {
      case 'title':
        return 'Title';
      case 'about':
        return 'About';
      case 'services':
        return 'Services';
      case 'contact':
        return 'Contact';
      case 'links':
        return 'Links';
      case 'image':
        return 'Images';
      case 'video':
        return 'Videos';
      case 'table':
        return 'Tables';
      case 'call_to_action':
        return 'Call to Action';
      case 'footer':
        return 'Footer';
      default:
        return 'Section';
    }
  }

  static bool isEditable(String type) {
    return {
      'title',
      'about',
      'services',
      'contact',
      'links',
      'image',
      'video',
      'table',
    }.contains(type);
  }
}
