import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'feature_template_provider.dart';

class FeatureTemplateScreen extends StatefulWidget {
  const FeatureTemplateScreen({super.key});

  @override
  State<FeatureTemplateScreen> createState() => _FeatureTemplateScreenState();
}

class _FeatureTemplateScreenState extends State<FeatureTemplateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FeatureTemplateProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeatureTemplateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Feature Template')),
      body: Center(
        child: provider.isLoading
            ? const CircularProgressIndicator()
            : const Text('Feature template ready'),
      ),
    );
  }
}
