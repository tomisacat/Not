#if canImport(NotMacros)
import NotMacros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

let testMacros: [String: Macro.Type] = [
    "Not": NotMacro.self,
]

// MARK: - Stored properties


@Test
func structBoolPeers() throws {
        assertMacroExpansion(
            """
            @Not
            struct Settings {
                var isDarkMode: Bool
                var enabled: Bool
                var count: Int
            }
            """,
            expandedSource: """
            struct Settings {
                var isDarkMode: Bool
                var enabled: Bool
                var count: Int

                var isNotDarkMode: Bool {
                    !isDarkMode
                }

                var isNotEnabled: Bool {
                    !enabled
                }
            }
            """,
            macros: testMacros
        )
    }


@Test
func letStoredBoolProperty() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                let isEnabled: Bool
            }
            """,
            expandedSource: """
            struct Example {
                let isEnabled: Bool

                var isNotEnabled: Bool {
                    !isEnabled
                }
            }
            """,
            macros: testMacros
        )
    }


@Test
func multipleBindingsOnOneLine() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                var isEnabled: Bool, isVisible: Bool
            }
            """,
            expandedSource: """
            struct Example {
                var isEnabled: Bool, isVisible: Bool

                var isNotEnabled: Bool {
                    !isEnabled
                }

                var isNotVisible: Bool {
                    !isVisible
                }
            }
            """,
            macros: testMacros
        )
    }


@Test
func emptyTypeGeneratesNoPeers() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                var count: Int
            }
            """,
            expandedSource: """
            struct Example {
                var count: Int
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Computed properties


@Test
func computedBoolProperty() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                var isEnabled: Bool {
                    true
                }
            }
            """,
            expandedSource: """
            struct Example {
                var isEnabled: Bool {
                    true
                }

                var isNotEnabled: Bool {
                    !isEnabled
                }
            }
            """,
            macros: testMacros
        )
    }


@Test
func explicitGetSetComputedProperty() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                var isEnabled: Bool {
                    get { true }
                    set { }
                }
            }
            """,
            expandedSource: """
            struct Example {
                var isEnabled: Bool {
                    get { true }
                    set { }
                }

                var isNotEnabled: Bool {
                    !isEnabled
                }
            }
            """,
            macros: testMacros
        )
    }


@Test
func skipSetterOnlyBoolProperty() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                var value: Bool {
                    set { }
                }
            }
            """,
            expandedSource: """
            struct Example {
                var value: Bool {
                    set { }
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Static and class properties


@Test
func staticBoolProperty() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                static var isEnabled: Bool
            }
            """,
            expandedSource: """
            struct Example {
                static var isEnabled: Bool

                static var isNotEnabled: Bool {
                    !isEnabled
                }
            }
            """,
            macros: testMacros
        )
    }


@Test
func staticLetBoolProperty() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                static let isEnabled: Bool = true
            }
            """,
            expandedSource: """
            struct Example {
                static let isEnabled: Bool = true

                static var isNotEnabled: Bool {
                    !isEnabled
                }
            }
            """,
            macros: testMacros
        )
    }


@Test
func classBoolProperty() throws {
        assertMacroExpansion(
            """
            @Not
            class Example {
                class var isEnabled: Bool
            }
            """,
            expandedSource: """
            class Example {
                class var isEnabled: Bool

                class var isNotEnabled: Bool {
                    !isEnabled
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Property wrappers and inferred types


@Test
func propertyWrapperBoolProperty() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                @State var isEnabled: Bool
                @Published var isVisible = false
            }
            """,
            expandedSource: """
            struct Example {
                @State var isEnabled: Bool
                @Published var isVisible = false

                var isNotEnabled: Bool {
                    !isEnabled
                }

                var isNotVisible: Bool {
                    !isVisible
                }
            }
            """,
            macros: testMacros
        )
    }


@Test
func mainActorProperty() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                @MainActor var isEnabled: Bool
            }
            """,
            expandedSource: """
            struct Example {
                @MainActor var isEnabled: Bool

                var isNotEnabled: Bool {
                    !isEnabled
                }
            }
            """,
            macros: testMacros
        )
    }


@Test
func inferredBoolFromTrueInitializer() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                var isEnabled = true
            }
            """,
            expandedSource: """
            struct Example {
                var isEnabled = true

                var isNotEnabled: Bool {
                    !isEnabled
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Type coverage


@Test
func actorBoolProperty() throws {
        assertMacroExpansion(
            """
            @Not
            actor Gatekeeper {
                var isLocked: Bool
            }
            """,
            expandedSource: """
            actor Gatekeeper {
                var isLocked: Bool

                var isNotLocked: Bool {
                    !isLocked
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Skipped properties


@Test
func skipOptionalBoolProperty() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                var isEnabled: Bool?
            }
            """,
            expandedSource: """
            struct Example {
                var isEnabled: Bool?
            }
            """,
            macros: testMacros
        )
    }


@Test
func skipNonBoolInferredInitializer() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                var count = 0
            }
            """,
            expandedSource: """
            struct Example {
                var count = 0
            }
            """,
            macros: testMacros
        )
    }


@Test
func skipPropertyMarkedWithNot() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                @Not var isEnabled: Bool
                var isVisible: Bool
            }
            """,
            expandedSource: """
            struct Example {
                var isEnabled: Bool
                var isVisible: Bool

                var isNotVisible: Bool {
                    !isVisible
                }
            }
            """,
            macros: testMacros
        )
    }


@Test
func skipMethodsAndNonVariableMembers() throws {
        assertMacroExpansion(
            """
            @Not
            struct Example {
                var isEnabled: Bool

                func refresh() {
                }
            }
            """,
            expandedSource: """
            struct Example {
                var isEnabled: Bool

                func refresh() {
                }

                var isNotEnabled: Bool {
                    !isEnabled
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Invalid attachment sites


@Test
func unsupportedExtensionProducesError() throws {
        assertMacroExpansion(
            """
            @Not
            extension String {}
            """,
            expandedSource: """
            extension String {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Not can only be attached to a struct, class, or actor.",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }


@Test
func unsupportedEnumProducesError() throws {
        assertMacroExpansion(
            """
            @Not
            enum Mode {
                case on
            }
            """,
            expandedSource: """
            enum Mode {
                case on
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Not can only be attached to a struct, class, or actor.",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }
#endif
