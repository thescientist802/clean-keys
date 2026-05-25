import Foundation

struct Settings: Codable {
    var timeoutSeconds: Int
    var overlayPinned: Bool
    var hardwareFailSafeEnabled: Bool
    var soundWarningsEnabled: Bool

    static let `default` = Settings(
        timeoutSeconds: 600,
        overlayPinned: false,
        hardwareFailSafeEnabled: true,
        soundWarningsEnabled: true
    )

    static let savedPath: URL = {
        let fm = FileManager.default
        return fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("com.scientist.CleanKeys")
            .appendingPathComponent("settings.json")
    }()

    static func load() -> Settings {
        do {
            let data = try Data(contentsOf: savedPath)
            let decoder = JSONDecoder()
            return try decoder.decode(Settings.self, from: data)
        } catch {
            return .default
        }
    }

    func save() throws {
        if !FileManager.default.fileExists(atPath: savedPath.deletingLastPathComponent().path) {
            try FileManager.default.createDirectory(
                at: savedPath.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: savedPath, options: .atomic)
    }
}