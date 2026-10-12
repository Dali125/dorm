# 0.1.0

* Initial release of **Relic**.
* GORM-inspired fluent query builder: `model()`, `where()`, `or()`, `not()`, `order()`, `limit()`, `offset()`, `pluck()`, `count()`.
* Schema auto-migration (`autoMigrate([User])`) and declarative column annotations.
* Zero-boilerplate code generation integration with `relic_orm_generator`.
* Aggregated auto-discovery (`initRelic()`).
* Structured, ANSI-colored SQL console logger reporting query duration in milliseconds, slow queries, and affected rows.
* Soft-delete support (`deletedAt`, `unscoped()`).
* Lifecycle callbacks & hooks (`beforeCreate`, `afterCreate`, `beforeUpdate`, `afterUpdate`, `beforeDelete`, `afterDelete`).
* ACID transactions via `db.transaction((tx) async { ... })`.
