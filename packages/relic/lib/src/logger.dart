/// Log levels for RELIC logger.
enum RelicLogLevel { silent, error, warn, info }

/// Backwards compatibility alias for [RelicLogLevel].
typedef GormLogLevel = RelicLogLevel;

/// Structured SQL logger interface matching Golang GORM logger.
abstract class RelicLogger {
  void logQuery({
    required String sql,
    List<dynamic>? params,
    required Duration duration,
    int? rowsAffected,
    Object? error,
  });

  void logInfo(String message);
  void logWarn(String message);
  void logError(String message, [Object? error]);

  /// Default logger printing colored / structured logs to console.
  static RelicLogger get standard => DefaultRelicLogger(level: RelicLogLevel.info);

  /// Silent logger that outputs nothing.
  static RelicLogger get silent => SilentRelicLogger();
}

/// Backwards compatibility alias for [RelicLogger].
typedef GormLogger = RelicLogger;

/// Default implementation of RELIC structured SQL logging.
class DefaultRelicLogger implements RelicLogger {
  final RelicLogLevel level;
  final Duration slowThreshold;
  final bool colorful;

  DefaultRelicLogger({
    this.level = RelicLogLevel.info,
    this.slowThreshold = const Duration(milliseconds: 200),
    this.colorful = true,
  });

  @override
  void logQuery({
    required String sql,
    List<dynamic>? params,
    required Duration duration,
    int? rowsAffected,
    Object? error,
  }) {
    if (level == RelicLogLevel.silent) return;

    final ms = duration.inMicroseconds / 1000.0;
    final timeStr = '${ms.toStringAsFixed(2)}ms';
    final rowsStr = rowsAffected != null ? '[rows: $rowsAffected]' : '';
    final paramStr = (params != null && params.isNotEmpty) ? ' | params: $params' : '';

    if (error != null) {
      if (level.index >= RelicLogLevel.error.index) {
        // ignore: avoid_print
        print(_red('[RELIC:ERROR] ($timeStr) $sql$paramStr => Error: $error'));
      }
      return;
    }

    if (duration >= slowThreshold) {
      if (level.index >= RelicLogLevel.warn.index) {
        // ignore: avoid_print
        print(_yellow('[RELIC:SLOW QUERY] ($timeStr) $rowsStr $sql$paramStr'));
      }
      return;
    }

    if (level.index >= RelicLogLevel.info.index) {
      // ignore: avoid_print
      print('${_cyan('[RELIC]')} ($timeStr) $rowsStr $sql$paramStr');
    }
  }

  @override
  void logInfo(String message) {
    if (level.index >= RelicLogLevel.info.index) {
      // ignore: avoid_print
      print('${_cyan('[RELIC:INFO] ')}$message');
    }
  }

  @override
  void logWarn(String message) {
    if (level.index >= RelicLogLevel.warn.index) {
      // ignore: avoid_print
      print('${_yellow('[RELIC:WARN] ')}$message');
    }
  }

  @override
  void logError(String message, [Object? error]) {
    if (level.index >= RelicLogLevel.error.index) {
      final err = error != null ? ' ($error)' : '';
      // ignore: avoid_print
      print('${_red('[RELIC:ERROR] ')}$message$err');
    }
  }

  String _cyan(String text) => colorful ? '\x1B[36m$text\x1B[0m' : text;
  String _yellow(String text) => colorful ? '\x1B[33m$text\x1B[0m' : text;
  String _red(String text) => colorful ? '\x1B[31m$text\x1B[0m' : text;
}

/// Backwards compatibility alias for [DefaultRelicLogger].
typedef DefaultGormLogger = DefaultRelicLogger;

class SilentRelicLogger implements RelicLogger {
  @override
  void logQuery({
    required String sql,
    List<dynamic>? params,
    required Duration duration,
    int? rowsAffected,
    Object? error,
  }) {}

  @override
  void logInfo(String message) {}

  @override
  void logWarn(String message) {}

  @override
  void logError(String message, [Object? error]) {}
}

/// Backwards compatibility alias for [SilentRelicLogger].
typedef SilentGormLogger = SilentRelicLogger;

