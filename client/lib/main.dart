import 'package:flutter/widgets.dart';
import 'package:time_keeper/utils/logger.dart';

void main() async {
  // Ensure flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  TkLogger().i('Initializing TK Logger');
}
