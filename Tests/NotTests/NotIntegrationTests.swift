import Not
import Testing

@Not
private struct StoredSettings {
    var isDarkMode: Bool
    var enabled: Bool
}

@Not
private struct ComputedSettings {
    var isEnabled: Bool { true }
}

@Not
private struct StaticSettings {
    static let isEnabled: Bool = true
}

@Not
private struct WrapperSettings {
    var notificationsEnabled: Bool
    var isVisible: Bool
}

@Not
private struct InferredSettings {
    var isActive = true
    var isHidden = false
}

@Not
private struct GetSetSettings {
    private var backingEnabled = true

    var isEnabled: Bool {
        get { backingEnabled }
        set { backingEnabled = newValue }
    }
}

@Not
private actor ActorSettings {
    var isLocked: Bool

    init(isLocked: Bool) {
        self.isLocked = isLocked
    }
}

@Test
func storedProperties() {
    let settings = StoredSettings(isDarkMode: true, enabled: false)

    #expect(settings.isDarkMode)
    #expect(!settings.isNotDarkMode)
    #expect(!settings.enabled)
    #expect(settings.isNotEnabled)
}

@Test
func computedProperty() {
    let settings = ComputedSettings()

    #expect(settings.isEnabled)
    #expect(!settings.isNotEnabled)
}

@Test
func staticProperty() {
    #expect(StaticSettings.isEnabled)
    #expect(!StaticSettings.isNotEnabled)
}

@Test
func explicitTypeWrapperBackedProperties() {
    let settings = WrapperSettings(notificationsEnabled: true, isVisible: false)

    #expect(settings.notificationsEnabled)
    #expect(!settings.isNotNotificationsEnabled)
    #expect(!settings.isVisible)
    #expect(settings.isNotVisible)
}

@Test
func inferredBoolInitializers() {
    let settings = InferredSettings()

    #expect(settings.isActive)
    #expect(!settings.isNotActive)
    #expect(!settings.isHidden)
    #expect(settings.isNotHidden)
}

@Test
func getSetComputedProperty() {
    var settings = GetSetSettings()

    #expect(settings.isEnabled)
    #expect(!settings.isNotEnabled)

    settings.isEnabled = false
    #expect(!settings.isEnabled)
    #expect(settings.isNotEnabled)
}

@Test
func actorProperty() async {
    let settings = ActorSettings(isLocked: true)

    let locked = await settings.isLocked
    let notLocked = await settings.isNotLocked

    #expect(locked)
    #expect(!notLocked)
}

@Test
func peersDoNotMutateOriginalStoredProperty() {
    let settings = StoredSettings(isDarkMode: true, enabled: true)
    _ = settings.isNotDarkMode
    _ = settings.isNotEnabled

    #expect(settings.isDarkMode)
    #expect(settings.enabled)
}
