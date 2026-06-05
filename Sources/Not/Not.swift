/// Adds read-only `isNot*` peers for `Bool` properties on annotated types.
///
/// Supports stored, computed (get-only or get/set), static/class, and
/// property-wrapper-backed properties (`@State`, `@Published`, etc.).
///
///     @Not
///     struct Settings {
///         var isDarkMode: Bool
///         @Published var notificationsEnabled: Bool
///         var isEnabled: Bool { true }
///     }
@attached(member, names: arbitrary)
public macro Not() = #externalMacro(module: "NotMacros", type: "NotMacro")
