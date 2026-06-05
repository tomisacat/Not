# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-06-05

### Added

- `@Not` member macro that generates read-only `isNot*` peers for `Bool` properties on annotated types
- Naming rules: `isEnabled` → `isNotEnabled`, `enabled` → `isNotEnabled`, `isDarkMode` → `isNotDarkMode`
- Support for stored properties (`var` and `let`)
- Support for computed properties with get-only or get/set accessors
- Support for `static` and `class` properties
- Support for property-wrapper-backed properties (e.g. `@State`, `@Published`, `@MainActor`)
- Support for inferred `Bool` types from `= true` / `= false` initializers
- Support for `struct`, `class`, and `actor` declarations
- `NotClient` executable demonstrating all supported usage patterns
- Swift Testing suite with macro expansion, naming, and integration tests
- MIT License
- GitHub pull request and issue templates

### Notes

- `Bool?`, setter-only properties, and properties marked with `@Not` are not supported in this release
- Peers use `!property` and do not mutate the original value

[Unreleased]: https://github.com/OWNER/Not/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/OWNER/Not/releases/tag/v1.0.0
