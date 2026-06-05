// NotMacro.swift
//
// Compiler plugin implementation for the `@Not` attached macro.
//
// When `@Not` is applied to a struct, class, or actor, this module scans the
// type's variable declarations and emits read-only `isNot*` computed properties
// that negate each eligible `Bool` property through its getter.

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - Errors

/// Errors surfaced during `@Not` macro expansion.
enum NotMacroError: Error, CustomStringConvertible {
    /// The macro was attached to a declaration other than a struct, class, or actor.
    case notAttachedToType

    var description: String {
        switch self {
        case .notAttachedToType:
            "@Not can only be attached to a struct, class, or actor."
        }
    }
}

// MARK: - Naming

/// Derives the `isNot*` peer name for a `Bool` property.
///
/// Examples:
///
/// | Property name            | Peer name                    |
/// |--------------------------|------------------------------|
/// | `enabled`                | `isNotEnabled`               |
/// | `isEnabled`              | `isNotEnabled`               |
/// | `isDarkMode`             | `isNotDarkMode`              |
/// | `notificationsEnabled`   | `isNotNotificationsEnabled`  |
///
/// Exposed as `package` so the test target can validate naming without making
/// it part of the macro's public API.
package enum NotNaming {
    /// Returns the peer property name for a given `Bool` property name.
    ///
    /// - Parameter propertyName: The identifier of the original property.
    /// - Returns: A name prefixed with `isNot` according to the naming rules.
    package static func isNotName(for propertyName: String) -> String {
        // `isEnabled` → replace leading `is` with `isNot` → `isNotEnabled`
        if propertyName.hasPrefix("is"), propertyName.count > 2 {
            let indexAfterIs = propertyName.index(propertyName.startIndex, offsetBy: 2)
            if propertyName[indexAfterIs].isUppercase {
                let suffix = propertyName[propertyName.index(propertyName.startIndex, offsetBy: 2)...]
                return "isNot" + suffix
            }
        }

        guard let first = propertyName.first else {
            return "isNot"
        }

        // `enabled` → `isNot` + `Enabled` → `isNotEnabled`
        return "isNot" + first.uppercased() + propertyName.dropFirst()
    }
}

// MARK: - Property discovery

/// A `Bool` property eligible for an `isNot*` peer, collected during scanning.
private struct BoolPropertyBinding {
    /// The original property identifier (e.g. `isEnabled`).
    let name: String
    /// The syntax token for the identifier, reused when generating `!identifier`.
    let identifier: TokenSyntax
    /// `"static "` or `"class "` when the source property is static/class; otherwise `""`.
    let modifierPrefix: String
}

/// Extracts the attribute name from an `@Attribute` syntax node.
///
/// Handles both `@State`-style (`IdentifierTypeSyntax`) and bare `@available`-style
/// (`DeclReferenceExprSyntax`) attribute spellings.
private func attributeName(from attribute: AttributeSyntax) -> String? {
    if let identifierType = attribute.attributeName.as(IdentifierTypeSyntax.self) {
        return identifierType.name.text
    }
    if let declRef = attribute.attributeName.as(DeclReferenceExprSyntax.self) {
        return declRef.baseName.text
    }
    return nil
}

/// Returns whether a property declaration is explicitly excluded via `@Not`.
///
/// Properties marked `@Not` are skipped so callers can opt individual members
/// out of peer generation on an otherwise annotated type.
private func hasNotAttribute(_ attributes: AttributeListSyntax) -> Bool {
    attributes.contains { element in
        guard case .attribute(let attribute) = element else {
            return false
        }
        return attributeName(from: attribute) == "Not"
    }
}

/// Returns whether a type syntax node is exactly `Bool` (non-optional).
///
/// Only unqualified `Bool` matches. `Bool?`, `Swift.Bool`, and generic aliases
/// are intentionally excluded.
private func isBoolType(_ typeSyntax: TypeSyntax?) -> Bool {
    guard let typeSyntax else {
        return false
    }

    if let identifierType = typeSyntax.as(IdentifierTypeSyntax.self) {
        return identifierType.name.text == "Bool"
    }

    return false
}

/// Returns whether a pattern binding represents a `Bool` property.
///
/// Matches when either:
/// - the binding has an explicit `: Bool` type annotation, or
/// - the binding is initialized with a boolean literal (`true` / `false`).
private func isBoolBinding(_ binding: PatternBindingSyntax) -> Bool {
    if isBoolType(binding.typeAnnotation?.type) {
        return true
    }

    guard let initializer = binding.initializer?.value else {
        return false
    }

    return initializer.is(BooleanLiteralExprSyntax.self)
}

/// Returns whether a binding has a getter and can be negated.
///
/// - Stored properties (no accessor block) → `true`
/// - Shorthand computed `{ expr }` → `true`
/// - Explicit `{ get }` or `{ get set }` → `true`
/// - Setter-only `{ set }` → `false`
private func hasBoolGetter(_ binding: PatternBindingSyntax) -> Bool {
    guard let accessorBlock = binding.accessorBlock else {
        return true
    }

    switch accessorBlock.accessors {
    case .accessors(let accessors):
        return accessors.contains { $0.accessorSpecifier.tokenKind == .keyword(.get) }
    case .getter:
        return true
    @unknown default:
        return false
    }
}

/// Returns the modifier prefix to copy onto a generated peer.
///
/// Only `static` and `class` are propagated. Access control (`private`,
/// `public`) and member attributes (`@MainActor`, `@Published`) are not copied.
private func modifierPrefix(for modifiers: DeclModifierListSyntax) -> String {
    if modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
        return "static "
    }
    if modifiers.contains(where: { $0.name.tokenKind == .keyword(.class) }) {
        return "class "
    }
    return ""
}

/// Collects every eligible `Bool` property in a type member block.
///
/// Iterates variable declarations and applies these filters:
///
/// 1. Must be a `VariableDeclSyntax` (not a function, nested type, etc.).
/// 2. Must not be marked `@Not`.
/// 3. Must have a getter (stored, shorthand computed, or explicit `get`).
/// 4. Must use a simple identifier pattern (no tuple destructuring).
/// 5. Must be `Bool` by annotation or boolean literal initializer.
///
/// Property wrappers (`@State`, `@Published`, etc.) are allowed; only `@Not`
/// on the property itself causes exclusion.
private func boolBindings(in memberBlock: MemberBlockSyntax?) -> [BoolPropertyBinding] {
    guard let memberBlock else {
        return []
    }

    var bindings: [BoolPropertyBinding] = []

    for member in memberBlock.members {
        guard let variable = member.decl.as(VariableDeclSyntax.self) else {
            continue
        }

        if hasNotAttribute(variable.attributes) {
            continue
        }

        let prefix = modifierPrefix(for: variable.modifiers)

        for binding in variable.bindings {
            guard hasBoolGetter(binding) else {
                continue
            }

            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
                continue
            }

            guard isBoolBinding(binding) else {
                continue
            }

            bindings.append(
                BoolPropertyBinding(
                    name: identifier.text,
                    identifier: identifier,
                    modifierPrefix: prefix
                )
            )
        }
    }

    return bindings
}

// MARK: - Macro

/// Implementation of the `@Not` attached member macro.
///
/// Attach to a struct, class, or actor to generate read-only peers:
///
/// ```swift
/// @Not
/// struct Settings {
///     var isEnabled: Bool
/// }
/// // → var isNotEnabled: Bool { !isEnabled }
/// ```
public struct NotMacro: MemberMacro {
    /// Expands `@Not` by emitting one read-only computed property per eligible
    /// `Bool` member on the attached type.
    ///
    /// - Parameters:
    ///   - node: The `@Not` attribute syntax.
    ///   - declaration: The struct, class, or actor the macro is attached to.
    ///   - protocols: Unused; required by the `MemberMacro` protocol.
    ///   - context: The macro expansion context.
    /// - Returns: Generated `var isNot*: Bool { !* }` member declarations.
    /// - Throws: ``NotMacroError/notAttachedToType`` when attached elsewhere.
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self)
            || declaration.is(ClassDeclSyntax.self)
            || declaration.is(ActorDeclSyntax.self)
        else {
            throw NotMacroError.notAttachedToType
        }

        return boolBindings(in: declaration.memberBlock).map { binding in
            let peerName = NotNaming.isNotName(for: binding.name)
            return DeclSyntax(
                """
                \(raw: binding.modifierPrefix)var \(raw: peerName): Bool {
                    !\(binding.identifier)
                }
                """
            )
        }
    }
}

// MARK: - Compiler plugin

/// Registers `NotMacro` with the Swift compiler plugin system.
@main
struct NotPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        NotMacro.self,
    ]
}
