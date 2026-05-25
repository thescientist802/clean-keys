import Foundation
import Combine

class Settings: ObservableObject, Codable {

    @Published var timeoutSeconds: Int
    @Published var overlayPinned: Bool
    @Published var hardwareFailSafeEnabled: Bool
    @Published var soundWarningsEnabled: Bool

    static let shared: Settings = {
        let loaded = Settings.load()
        return loaded
    }()

    static let `default` = Settings(
        timeoutSeconds: 600,
        overlayPinned: false,
        hardwareFailSafeEnabled: true,
        soundWarningsEnabled: true
    )

    static let savedPath: URL = {
        let fm = FileManager.default
        let basePath = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        return basePath
            .appendingPathComponent("com.scientist.CleanKeys")
            .appendingPathComponent("settings.json")
    }()

    private enum CodingKeys: String, CodingKey {
        case timeoutSeconds
        case overlayPinned
        case hardwareFailSafeEnabled
        case soundWarningsEnabled
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timeoutSeconds = try container.decode(Int.self, forKey: .timeoutSeconds)
        overlayPinned = try container.decode(Bool.self, forKey: .overlayPinned)
        hardwareFailSafeEnabled = try container.decode(Bool.self, forKey: .hardwareFailSafeEnabled)
        soundWarningsEnabled = try container.decode(Bool.self, forKey: .soundWarningsEnabled)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timeoutSeconds, forKey: .timeoutSeconds)
        try container.encode(overlayPinned, forKey: .overlayPinned)
        try container.encode(hardwareFailSafeEnabled, forKey: .hardwareFailSafeEnabled)
        try container.encode(soundWarningsEnabled, forKey: .soundWarningsEnabled)
    }

    init(
        timeoutSeconds: Int,
        overlayPinned: Bool,
        hardwareFailSafeEnabled: Bool,
        soundWarningsEnabled: Bool
    ) {
        self.timeoutSeconds = timeoutSeconds
        self.overlayPinned = overlayPinned
        self.hardwareFailSafeEnabled = hardwareFailSafeEnabled
        self.soundWarningsEnabled = soundWarningsEnabled
    }

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
