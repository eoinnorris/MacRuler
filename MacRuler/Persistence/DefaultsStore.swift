import Foundation

protocol DefaultsStoring: AnyObject {
    func string(forKey defaultName: String) -> String?
    func bool(forKey defaultName: String) -> Bool
    func object(forKey defaultName: String) -> Any?
    func double(forKey defaultName: String) -> Double
    func integer(forKey defaultName: String) -> Int
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

extension UserDefaults: DefaultsStoring {}

final class InMemoryDefaultsStore: DefaultsStoring {
    private var storage: [String: Any] = [:]

    func string(forKey defaultName: String) -> String? {
        storage[defaultName] as? String
    }

    func bool(forKey defaultName: String) -> Bool {
        storage[defaultName] as? Bool ?? false
    }

    func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }

    func double(forKey defaultName: String) -> Double {
        storage[defaultName] as? Double ?? 0
    }

    func integer(forKey defaultName: String) -> Int {
        storage[defaultName] as? Int ?? 0
    }

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
}
