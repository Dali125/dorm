/// Log levels for DORM logger.
enum DormLogLevel { silent, error, warn, info }

/// Backwards compatibility alias for [DormLogLevel].
typedef GormLogLevel = DormLogLevel;

/// Structured SQL logger interface matching Golang GORM logger.
abstract class DormLogger {
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
  static DormLogger get standard => DefaultDormLogger(level: DormLogLevel.info);

  /// Silent logger that outputs nothing.
  static DormLogger get silent => SilentDormLogger();
}

/// Backwards compatibility alias for [DormLogger].
typedef GormLogger = DormLogger;

/// Default implementation of DORM structured SQL logging.
class DefaultDormLogger implements DormLogger {
  final DormLogLevel level;
  final Duration slowThreshold;
  final bool colorful;

  DefaultDormLogger({
    this.level = DormLogLevel.info,
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
    if (level == DormLogLevel.silent) return;

    final ms = duration.inMicroseconds / 1000.0;
    final timeStr = '${ms.toStringAsFixed(2)}ms';
    final rowsStr = rowsAffected != null ? '[rows: $rowsAffected]' : '';
    final paramStr = (params != null && params.isNotEmpty) ? ' | params: $params' : '';

    if (error != null) {
      if (level.index >= DormLogLevel.error.index) {
        // ignore: avoid_print
        print(_red('[DORM:ERROR] ($timeStr) $sql$paramStr => Error: $error'));
      }
      return;
    }

    if (duration >= slowThreshold) {
      if (level.index >= DormLogLevel.warn.index) {
        // ignore: avoid_print
        print(_yellow('[DORM:SLOW QUERY] ($timeStr) $rowsStr $sql$paramStr'));
      }
      return;
    }

    if (level.index >= DormLogLevel.info.index) {
      // ignore: avoid_print
      print('${_cyan('[DORM]')} ($timeStr) $rowsStr $sql$paramStr');
    }
  }

  @override
  void logInfo(String message) {
    if (level.index >= DormLogLevel.info.index) {
      // ignore: avoid_print
      print('${_cyan('[DORM:INFO] ')}$message');
    }
  }

  @override
  void logWarn(String message) {
    if (level.index >= DormLogLevel.warn.index) {
      // ignore: avoid_print
      print('${_yellow('[DORM:WARN] ')}$message');
    }
  }

  @override
  void logError(String message, [Object? error]) {
    if (level.index >= DormLogLevel.error.index) {
      final err = error != null ? ' ($error)' : '';
      // ignore: avoid_print
      print('${_red('[DORM:ERROR] ')}$message$err');
    }
  }

  String _cyan(String text) => colorful ? '\x1B[36m$text\x1B[0m' : text;
  String _yellow(String text) => colorful ? '\x1B[33m$text\x1B[0m' : text;
  String _red(String text) => colorful ? '\x1B[31m$text\x1B[0m' : text;
}

/// Backwards compatibility alias for [DefaultDormLogger].
typedef DefaultGormLogger = DefaultDormLogger;

class SilentDormLogger implements DormLogger {
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

/// Backwards compatibility alias for [SilentDormLogger].
typedef SilentGormLogger = SilentDormLogger;

