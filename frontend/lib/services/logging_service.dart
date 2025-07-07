import 'package:logging/logging.dart';
import 'dart:developer' as developer;

class LoggingService {
  static final Logger _logger = Logger('ApiService');

  static void setup() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      developer.log(
        '${record.level.name}: ${record.message}',
        time: record.time,
        level: record.level.value,
        name: record.loggerName,
      );
    });
  }

  static Logger get logger => _logger;
}
