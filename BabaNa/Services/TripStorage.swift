import Foundation

struct TripStorage {
    let directory: URL

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory,
                                                               in: .userDomainMask)[0]
            .appendingPathComponent("BabaNa", isDirectory: true)
    }

    private func fileURL(userID: String) -> URL {
        // Encode the UID so it cannot introduce path separators into a filename.
        let key = userID.utf8.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent("account-\(key).json")
    }

    func load(userID: String) throws -> TripSnapshot {
        let url = fileURL(userID: userID)
        guard FileManager.default.fileExists(atPath: url.path) else { return TripSnapshot() }
        return try JSONDecoder().decode(TripSnapshot.self, from: Data(contentsOf: url))
    }

    func save(_ snapshot: TripSnapshot, userID: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(snapshot)
        #if os(iOS)
        try data.write(to: fileURL(userID: userID), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: fileURL(userID: userID), options: .atomic)
        #endif
    }
}
