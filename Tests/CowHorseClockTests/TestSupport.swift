import Foundation

final class InMemoryKeyValueStore: KeyValueStore {
    var values: [String: Data] = [:]

    func data(forKey defaultName: String) -> Data? {
        values[defaultName]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        values[defaultName] = value as? Data
    }
}

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

struct TestCase {
    let name: String
    let run: @MainActor () throws -> Void
}

func expect(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String
) throws {
    guard condition() else {
        throw TestFailure(description: message())
    }
}

func expectEqual<T: Equatable>(
    _ actual: @autoclosure () -> T,
    _ expected: @autoclosure () -> T,
    _ label: String
) throws {
    let actualValue = actual()
    let expectedValue = expected()
    guard actualValue == expectedValue else {
        throw TestFailure(
            description: "\(label): expected \(expectedValue), got \(actualValue)"
        )
    }
}
