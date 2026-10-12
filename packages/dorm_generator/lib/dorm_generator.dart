import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/dorm_generator.dart';
import 'src/dorm_init_builder.dart';

Builder dormBuilder(BuilderOptions options) =>
    SharedPartBuilder([DormGenerator()], 'dorm');

Builder dormInitBuilder(BuilderOptions options) =>
    DormInitBuilder();

// Backwards compatibility aliases
Builder gormBuilder(BuilderOptions options) => dormBuilder(options);
Builder gormInitBuilder(BuilderOptions options) => dormInitBuilder(options);

