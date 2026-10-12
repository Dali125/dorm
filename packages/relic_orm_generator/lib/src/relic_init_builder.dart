import 'dart:async';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// Aggregates all model files and generates a single central `lib/relic.init.dart` file.
/// This allows initializing the entire database schema registry with a single call: `initRelic();`
class RelicInitBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions = const {
    r'$lib$': ['relic.init.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final modelFiles = await buildStep.findAssets(Glob('lib/**.dart')).toList();

    final imports = <String>{};
    final registrationCalls = <String>[];

    final entityRegex = RegExp(r'@(?:RelicEntity|GormEntity)\b');
    final classRegex = RegExp(r'class\s+([A-Za-z0-9_]+)');

    for (final asset in modelFiles) {
      // Skip already generated files
      if (asset.path.endsWith('.g.dart') ||
          asset.path.endsWith('relic.init.dart') ||
          asset.path.endsWith('gorm.init.dart')) {
        continue;
      }

      final content = await buildStep.readAsString(asset);
      if (entityRegex.hasMatch(content) && content.contains('.g.dart')) {
        // Found RELIC entity file
        final relativeImport = asset.path.replaceFirst('lib/', '');
        imports.add("import '$relativeImport';");

        // Find entity class names
        final matches = entityRegex.allMatches(content);
        for (final match in matches) {
          final afterMatch = content.substring(match.end);
          final classMatch = classRegex.firstMatch(afterMatch);
          if (classMatch != null) {
            final className = classMatch.group(1);
            if (className != null) {
              registrationCalls.add('  register${className}Schema();');
            }
          }
        }
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// **************************************************************************');
    buffer.writeln('// RelicInitBuilder - Aggregated Auto-Discovery Registry');
    buffer.writeln('// **************************************************************************');
    buffer.writeln();

    for (final imp in imports.toList()..sort()) {
      buffer.writeln(imp);
    }
    buffer.writeln();

    buffer.writeln('/// Automatically registers all @RelicEntity models into SchemaRegistry.');
    buffer.writeln('/// Call this once before calling `relicDb.autoMigrate()`.');
    buffer.writeln('void initRelic() {');
    for (final call in registrationCalls) {
      buffer.writeln(call);
    }
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('/// Backwards compatibility alias for [initRelic].');
    buffer.writeln('void initGorm() => initRelic();');
    buffer.writeln();

    final outputId = AssetId(buildStep.inputId.package, 'lib/relic.init.dart');
    await buildStep.writeAsString(outputId, buffer.toString());
  }
}

/// Backwards compatibility alias for [RelicInitBuilder].
typedef GormInitBuilder = RelicInitBuilder;

