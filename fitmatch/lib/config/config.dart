import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class Config {
  // URLs da API
  static const String productionApiUrl =
      'https://personal-api-a5n6.onrender.com';
  static const String developmentApiUrl = 'http://localhost:8000';

  // URL atual baseada na URL do navegador
  static String get apiUrl {
    // Se estiver rodando na web, verifica a URL atual
    if (kIsWeb) {
      final currentUrl = html.window.location.href;

      // Se a URL contém localhost ou 127.0.0.1, usa desenvolvimento
      if (currentUrl.contains('localhost') ||
          currentUrl.contains('127.0.0.1')) {
        return developmentApiUrl;
      }

      // Caso contrário, usa produção
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
