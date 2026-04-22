import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'feature_template_provider.dart';
import 'feature_template_screen.dart';

class FeatureTemplateRoutes {
  static const screen = '/feature_template';

  static Map<String, WidgetBuilder> routes = {
    screen: (_) => ChangeNotifierProvider(
      create: (_) => FeatureTemplateProvider(),
      child: const FeatureTemplateScreen(),
    ),
  };
}
