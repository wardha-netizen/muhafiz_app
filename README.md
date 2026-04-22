# muhafiz_1

A new Flutter project.

## Feature Template (for new screens)

Use this template to add new features quickly with the current Feature-First structure:

- Template folder: `lib/features/feature_template/`
- Files included:
  - `feature_template_screen.dart`
  - `feature_template_provider.dart`
  - `feature_template_routes.dart`
  - `feature_template.dart` (barrel export)

### How to create a new feature

1. Copy `lib/features/feature_template/` to `lib/features/<your_feature>/`.
2. Rename files/classes from `FeatureTemplate...` to your feature names.
3. Add exports in `lib/features/<your_feature>/<your_feature>.dart`.
4. Register routes in `lib/core/app_setup.dart` (or merge route maps if preferred).
5. If needed, add a route constant in `lib/core/app_routes.dart`.

### Suggested naming convention

- Screen: `<FeatureName>Screen`
- Provider: `<FeatureName>Provider`
- Routes helper: `<FeatureName>Routes`

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
