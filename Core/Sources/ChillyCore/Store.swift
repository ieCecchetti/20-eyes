import Foundation

/// JSON files in the App Group container, so the app and the widget share them.
public enum Store {
    public static let stateFile = "state.json"
    public static let statsFile = "stats.json"

    public static var directory: URL {
        if let group = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String,
           let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) {
            return url
        }
        // Unsigned dev builds have no App Group; the widget won't see this data.
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ChillyEye", isDirectory: true)
    }

    public static func load<T: Decodable>(_ type: T.Type, from file: String, in dir: URL = directory) -> T? {
        guard let data = try? Data(contentsOf: dir.appendingPathComponent(file)) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    public static func save<T: Encodable>(_ value: T, to file: String, in dir: URL = directory) throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try encoder.encode(value).write(to: dir.appendingPathComponent(file), options: .atomic)
    }

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
}
