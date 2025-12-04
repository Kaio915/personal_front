import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class Config {
  // URLs da API
  static const String productionApiUrl =
      'https://personal-api-1-qkog.onrender.com';
  static const String developmentApiUrl = 'http://127.0.0.1:8000';
    // Production front URL to detect hosting environment
    static const String productionFrontUrl = 'https://personal-front-2.onrender.com';

  // URL atual baseada na URL do navegador
  static String get apiUrl {
    // Se estiver rodando na web, verifica a URL atual
    if (kIsWeb) {
      final currentUrl = html.window.location.href;

      // If running from the known production front URL, use production backend
      if (currentUrl.contains(productionFrontUrl)) {
        return productionApiUrl;
      }

      // If the URL contains localhost or 127.0.0.1, use development backend
      if (currentUrl.contains('localhost') || currentUrl.contains('127.0.0.1')) {
        return developmentApiUrl;
      }

      // Default to production API URL when not explicitly local
      return productionApiUrl;
    }

    // Para mobile/desktop, usa o modo de compilação
    if (kReleaseMode) {
      return productionApiUrl;
    }

    return developmentApiUrl;
  }

  // Também pode verificar se está rodando na web
  static bool get isWeb => kIsWeb;

  // Versão do app
  static const String appVersion = '1.0.0';

  // Timeout das requisições
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
