import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/relic_generator.dart';
import 'src/relic_init_builder.dart';

Builder relicBuilder(BuilderOptions options) =>
    SharedPartBuilder([RelicGenerator()], 'relic');

Builder relicInitBuilder(BuilderOptions options) =>
    RelicInitBuilder();

// Backwards compatibility aliases
Builder gormBuilder(BuilderOptions options) => relicBuilder(options);
Builder gormInitBuilder(BuilderOptions options) => relicInitBuilder(options);

