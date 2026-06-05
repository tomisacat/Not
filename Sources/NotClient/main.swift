import Not

// MARK: - Stored properties

@Not
struct StoredExample {
    var isDarkMode: Bool
    let isEnabled: Bool
}

// MARK: - Computed properties

@Not
struct ComputedExample {
    var isEnabled: Bool { true }
}

@Not
struct GetSetExample {
    private var backingVisible = false

    var isVisible: Bool {
        get { backingVisible }
        set { backingVisible = newValue }
    }
}

// MARK: - Static and class properties

@Not
struct StaticExample {
    static let isEnabled: Bool = true
    static let isLocked: Bool = false
}

@MainActor
@Not
struct MutableStaticExample {
    static var isEnabled: Bool = true
}

@Not
class ClassExample {
    class var isActive: Bool { true }
}

// MARK: - Inferred Bool initializers

@Not
struct InferredExample {
    var isActive = true
    var isHidden = false
}

// MARK: - Property-wrapper-backed properties

@propertyWrapper
struct Flag {
    var wrappedValue: Bool

    init(wrappedValue: Bool) {
        self.wrappedValue = wrappedValue
    }
}

@Not
struct WrapperExample {
    @Flag var isEnabled: Bool
    @Flag var isVisible = false
}

// MARK: - Actor

@Not
actor Gatekeeper {
    var isLocked: Bool

    init(isLocked: Bool) {
        self.isLocked = isLocked
    }
}

// MARK: - Demo

@main
enum NotClient {
    static func main() async {
        print("=== Stored properties ===")
        let stored = StoredExample(isDarkMode: true, isEnabled: false)
        print("isDarkMode: \(stored.isDarkMode), isNotDarkMode: \(stored.isNotDarkMode)")
        print("isEnabled: \(stored.isEnabled), isNotEnabled: \(stored.isNotEnabled)")

        print("\n=== Computed properties ===")
        let computed = ComputedExample()
        print("isEnabled: \(computed.isEnabled), isNotEnabled: \(computed.isNotEnabled)")

        var getSet = GetSetExample()
        print("isVisible: \(getSet.isVisible), isNotVisible: \(getSet.isNotVisible)")
        getSet.isVisible = true
        print("after set true -> isVisible: \(getSet.isVisible), isNotVisible: \(getSet.isNotVisible)")

        print("\n=== Static properties ===")
        print("isEnabled: \(StaticExample.isEnabled), isNotEnabled: \(StaticExample.isNotEnabled)")
        print("isLocked: \(StaticExample.isLocked), isNotLocked: \(StaticExample.isNotLocked)")
        print("isEnabled (mutable static): \(MutableStaticExample.isEnabled), isNotEnabled: \(MutableStaticExample.isNotEnabled)")
        MutableStaticExample.isEnabled = false
        print("after mutation -> isEnabled: \(MutableStaticExample.isEnabled), isNotEnabled: \(MutableStaticExample.isNotEnabled)")

        print("\n=== Class property ===")
        print("isActive: \(ClassExample.isActive), isNotActive: \(ClassExample.isNotActive)")

        print("\n=== Inferred Bool initializers ===")
        let inferred = InferredExample()
        print("isActive: \(inferred.isActive), isNotActive: \(inferred.isNotActive)")
        print("isHidden: \(inferred.isHidden), isNotHidden: \(inferred.isNotHidden)")

        print("\n=== Property-wrapper-backed properties ===")
        let wrapped = WrapperExample(isEnabled: true)
        print("isEnabled: \(wrapped.isEnabled), isNotEnabled: \(wrapped.isNotEnabled)")
        print("isVisible: \(wrapped.isVisible), isNotVisible: \(wrapped.isNotVisible)")

        print("\n=== Actor property ===")
        let gate = Gatekeeper(isLocked: true)
        print("isLocked: \(await gate.isLocked), isNotLocked: \(await gate.isNotLocked)")
    }
}
