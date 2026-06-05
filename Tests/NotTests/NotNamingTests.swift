#if canImport(NotMacros)
import NotMacros
import Testing

@Test
func isPrefixedPropertyNaming() {
    #expect(NotNaming.isNotName(for: "isEnabled") == "isNotEnabled")
    #expect(NotNaming.isNotName(for: "isDarkMode") == "isNotDarkMode")
}

@Test
func nonIsPrefixedPropertyNaming() {
    #expect(NotNaming.isNotName(for: "enabled") == "isNotEnabled")
    #expect(NotNaming.isNotName(for: "notificationsEnabled") == "isNotNotificationsEnabled")
    #expect(NotNaming.isNotName(for: "darkMode") == "isNotDarkMode")
}

@Test
func isPrefixWithoutUppercaseSuffixUsesDefaultRule() {
    #expect(NotNaming.isNotName(for: "is") == "isNotIs")
    #expect(NotNaming.isNotName(for: "issue") == "isNotIssue")
}

@Test
func emptyNameNaming() {
    #expect(NotNaming.isNotName(for: "") == "isNot")
}
#endif
