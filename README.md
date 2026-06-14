# Not

<div align="center">

[![CI](https://github.com/tomisacat/Not/actions/workflows/ci.yml/badge.svg)](https://github.com/tomisacat/Not/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/tomisacat/Not)](https://github.com/tomisacat/Not/releases)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2013+|macOS%2010.15+|tvOS%2013+|watchOS%206+-lightgrey)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

A Swift macro that generates read-only `isNot*` computed properties for every eligible `Bool` property on a type.

Instead of writing negated checks by hand, annotate a type with `@Not` and get peers like `isNotEnabled` for `isEnabled`, or `isNotDarkMode` for `isDarkMode`.

```swift
import Not

@Not
struct Settings {
    var isDarkMode: Bool
    var notificationsEnabled: Bool
}

let settings = Settings(isDarkMode: true, notificationsEnabled: false)

settings.isDarkMode                  // true
settings.isNotDarkMode                 // false
settings.isNotNotificationsEnabled   // true
```

Peers are **read-only** and **do not mutate** the original property. They evaluate `!property` through the property's getter.

## Requirements

- Swift 6.2+
- macOS 10.15+
- iOS 13+
- tvOS 13+
- watchOS 6+
- macCatalyst 13+

Macro expansion requires a Swift toolchain with macro support (Xcode 16+ or a recent Swift 6 compiler).

## Installation

Add Not to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/tomisacat/Not.git", from: "1.0.0"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "Not", package: "Not"),
        ]
    ),
]
```

Then import it where you use the macro:

```swift
import Not
```

## Usage

Apply `@Not` to a `struct`, `class`, or `actor`. The macro scans the type's members and generates one read-only peer per eligible `Bool` property.

```swift
@Not
struct FeatureFlags {
    var isEnabled: Bool
    let isLocked: Bool
    var isVisible: Bool { true }

    static let isDefaultOn: Bool = false
}
```

Expands to include:

```swift
var isNotEnabled: Bool { !isEnabled }
var isNotLocked: Bool { !isLocked }
var isNotVisible: Bool { !isVisible }
static var isNotDefaultOn: Bool { !isDefaultOn }
```

### Supported property kinds

| Kind | Example | Generated peer |
|------|---------|----------------|
| Stored `var` | `var isEnabled: Bool` | `var isNotEnabled: Bool { !isEnabled }` |
| Stored `let` | `let isLocked: Bool` | `var isNotLocked: Bool { !isLocked }` |
| Computed (getter) | `var isEnabled: Bool { true }` | `var isNotEnabled: Bool { !isEnabled }` |
| Computed (get/set) | `var isEnabled: Bool { get set }` | `var isNotEnabled: Bool { !isEnabled }` |
| `static` | `static var isEnabled: Bool` | `static var isNotEnabled: Bool { !isEnabled }` |
| `static let` | `static let isEnabled: Bool = true` | `static var isNotEnabled: Bool { !isEnabled }` |
| `class` | `class var isEnabled: Bool` | `class var isNotEnabled: Bool { !isEnabled }` |
| Property wrappers | `@State var isEnabled: Bool` | `var isNotEnabled: Bool { !isEnabled }` |
| Inferred `Bool` | `var isActive = true` | `var isNotActive: Bool { !isActive }` |
| Multiple bindings | `var a: Bool, b: Bool` | `isNotA`, `isNotB` |

Works on `struct`, `class`, and `actor` types.

### Naming rules

The generated name is derived from the original property name:

| Original property | Generated peer |
|-------------------|----------------|
| `enabled` | `isNotEnabled` |
| `isEnabled` | `isNotEnabled` |
| `isDarkMode` | `isNotDarkMode` |
| `notificationsEnabled` | `isNotNotificationsEnabled` |

Rules:

1. If the name starts with `is` followed by an uppercase letter, replace the leading `is` with `isNot`.
   - `isEnabled` → `isNotEnabled`
2. Otherwise, prefix `isNot` and capitalize the first character of the original name.
   - `enabled` → `isNotEnabled`

### Read-only peers vs `toggle()`

`@Not` and `Bool.toggle()` solve different problems:

| API | Behavior |
|-----|----------|
| `settings.isNotEnabled` | Read-only negated view; original value unchanged |
| `settings.isEnabled.toggle()` | Mutates the stored property in place |

Use `@Not` when you want a convenient negated getter. Use `toggle()` when you want to flip a stored value.

## Examples

### Stored and computed properties

```swift
@Not
struct UserPreferences {
    var isDarkMode: Bool
    var isEnabled: Bool { true }
}
```

### Property wrappers

Works with property-wrapper-backed properties. Access goes through the wrapper's getter:

```swift
@Not
struct ContentViewModel {
    @Published var isVisible: Bool
    @State var isExpanded = false
}
```

### Static and class properties

```swift
@Not
struct Config {
    static let isProduction: Bool = true
}

@Not
class BaseFlags {
    class var isActive: Bool { true }
}
```

### Actor-isolated properties

```swift
@Not
actor Gatekeeper {
    var isLocked: Bool

    init(isLocked: Bool) {
        self.isLocked = isLocked
    }
}

let gate = Gatekeeper(isLocked: true)
await gate.isNotLocked  // false
```

See [`Sources/NotClient/main.swift`](Sources/NotClient/main.swift) for a runnable demo of every supported pattern.

## Limitations

The macro **does not** generate peers for:

| Case | Reason |
|------|--------|
| `Bool?` | Optional negation is ambiguous |
| Setter-only properties | No getter to negate |
| Properties marked `@Not` | Explicitly excluded |
| Non-`Bool` types | Including inferred non-Bool initializers like `var count = 0` |
| `extension`, `enum`, `protocol` | Invalid attachment site |

### Naming collisions

If two properties map to the same peer name, the macro emits duplicate declarations and compilation fails. For example, both `enabled` and `isEnabled` generate `isNotEnabled`. Use distinct base names or exclude one with `@Not` on the property.

### Access control

Generated peers do not copy access modifiers or attributes (such as `@MainActor`) from the original property. If you need matching isolation, you may need to adjust access manually or wrap usage accordingly.

## Development

Clone the repository and run:

```bash
swift build
swift test
swift run NotClient
```

Tests use [Swift Testing](https://developer.apple.com/documentation/testing). For Swift Testing-only output:

```bash
swift test --disable-xctest
```

### Project structure

```
Not/
├── Sources/
│   ├── Not/              Public macro declaration
│   ├── NotMacros/        Macro implementation
│   └── NotClient/        Runnable usage examples
├── Tests/
│   └── NotTests/         Expansion, naming, and integration tests
├── CHANGELOG.md
└── LICENSE
```

## Contributing

Bug reports and feature requests are welcome. Use the GitHub issue templates when opening a new issue, and follow the pull request template when submitting changes.

Please include tests for macro behavior changes:

- **Expansion tests** for compile-time output in `Tests/NotTests/NotMacroExpansionTests.swift`
- **Integration tests** for runtime behavior in `Tests/NotTests/NotIntegrationTests.swift`
- **Naming tests** for peer naming rules in `Tests/NotTests/NotNamingTests.swift`

## License

MIT License. See [LICENSE](LICENSE).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
