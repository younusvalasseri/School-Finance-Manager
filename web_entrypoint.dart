import 'package:week7_institute_project_2/main.dart' as entrypoint;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() {
  // Ensures that Flutter Web uses the correct entry point.
  setUrlStrategy(PathUrlStrategy());
  entrypoint.main();
}
