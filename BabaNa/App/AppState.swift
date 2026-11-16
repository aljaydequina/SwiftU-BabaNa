import Foundation
import Combine

// Mutations originate on the main queue (SwiftUI, auth, or TripMonitor).
final class AppState: ObservableObject {
    @Published var hasFinishedOnboarding = false { didSet { persist() } }
    @Published var savedStops: [SavedStop] = [] { didSet { persist() } }
    @Published private(set) var trips: [TripRecord] = []
    @Published private(set) var recentDestinations: [Destination] = []
    @Published private(set) var activeTrip: ActiveTrip?
    @Published var arrivalDestination: Destination?
    @Published var notice: String?
    @Published var storageError: String?

    private let storage: TripStorage
    private let cloud = FirestoreTripStore()
    @Published private(set) var cloudSyncStatus = "Not connected"
    private var cloudReady = false
    private var changedDuringCloudLoad = false
    private var userID: String?
    private var isLoadingAccount = false

    init(storage: TripStorage = TripStorage()) { self.storage = storage }
    var isTripActive: Bool { activeTrip != nil }

    func loadAccount(_ id: String?) {
        guard id != userID else { return }
        isLoadingAccount = true
        cloudReady = false
        changedDuringCloudLoad = false
        cloudSyncStatus = id == nil ? "Not connected" : "Loading cloud data…"
        userID = id
        let snapshot: TripSnapshot
        do {
            snapshot = try id.map { try storage.load(userID: $0) } ?? TripSnapshot()
            storageError = nil
        } catch {
            snapshot = TripSnapshot()
            storageError = "Saved data could not be read. Your existing file has been kept."
        }
        hasFinishedOnboarding = snapshot.hasFinishedOnboarding
        savedStops = snapshot.savedStops
        trips = snapshot.trips
        recentDestinations = snapshot.recentDestinations
        activeTrip = nil
        arrivalDestination = nil
        notice = nil
        // Standard GPS updates cannot survive a force-quit. Never imply that an
        // old reminder kept running; record it once and require an explicit restart.
        if let interrupted = snapshot.activeTrip {
            trips.insert(TripRecord(id: interrupted.id, destination: interrupted.destination.name,
                                    status: .interrupted, reminderMeters: interrupted.reminderMeters,
                                    date: interrupted.startedAt), at: 0)
            notice = "Your previous trip was interrupted. Start it again to receive reminders."
        }
        isLoadingAccount = false
        if snapshot.activeTrip != nil { persist() }
        guard let id else { return }
        cloud.load(userID: id) { [weak self] result in
            guard let self, self.userID == id else { return }
            self.cloudReady = true
            switch result {
            case .failure(let error):
                self.cloudSyncStatus = "Cloud unavailable: \(error.localizedDescription)"
                // Local data remains intact; subsequent changes will retry cloud writes.
                if self.changedDuringCloudLoad { self.persist() }
            case .success(let remote):
                if self.changedDuringCloudLoad {
                    // Don't replace actions made on this device while the download was pending.
                    self.persist()
                } else if let remote {
                    self.isLoadingAccount = true
                    self.hasFinishedOnboarding = remote.hasFinishedOnboarding
                    self.savedStops = remote.savedStops
                    self.trips = remote.trips
                    self.recentDestinations = remote.recentDestinations
                    self.isLoadingAccount = false
                    self.cloudSyncStatus = "Synced with Firestore"
                    self.persistLocalOnly()
                } else {
                    // First cloud login: migrate the existing per-user local snapshot.
                    self.persist()
                }
            }
        }
    }

    @discardableResult
    func startTrip(destination: Destination, reminderMeters: Double) -> Bool {
        guard userID != nil, activeTrip == nil,
              destination.isValid, TripRules.isValidReminder(reminderMeters) else { return false }
        arrivalDestination = nil
        notice = nil
        activeTrip = ActiveTrip(destination: destination, reminderMeters: reminderMeters)
        recentDestinations.removeAll { $0.isSamePlace(as: destination) }
        recentDestinations.insert(destination, at: 0)
        recentDestinations = Array(recentDestinations.prefix(10))
        persist()
        return true
    }

    func markApproachingSent(tripID: UUID) {
        guard activeTrip?.id == tripID else { return }
        activeTrip?.didSendApproachingAlert = true
        persist()
    }

    func endTrip(status: TripStatus) {
        guard let trip = activeTrip else { return }
        if status == .completed { arrivalDestination = trip.destination }
        trips.insert(TripRecord(id: trip.id, destination: trip.destination.name, status: status,
                                reminderMeters: trip.reminderMeters, date: Date()), at: 0)
        activeTrip = nil
        persist()
    }

    func saveStop(label: String, icon: String, destination: Destination) {
        guard destination.isValid else { return }
        let cleanLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        savedStops.append(SavedStop(label: cleanLabel.isEmpty ? destination.name : cleanLabel,
                                    icon: icon, destination: destination))
    }

    private func snapshot() -> TripSnapshot {
        TripSnapshot(hasFinishedOnboarding: hasFinishedOnboarding,
                     savedStops: savedStops, trips: trips,
                     recentDestinations: recentDestinations,
                     activeTrip: activeTrip)
    }

    private func persistLocalOnly() {
        guard !isLoadingAccount, let userID else { return }
        do {
            try storage.save(snapshot(), userID: userID)
            storageError = nil
        } catch {
            storageError = "Changes could not be saved on this iPhone. Check available storage."
        }
    }

    private func persist() {
        guard !isLoadingAccount, let userID else { return }
        persistLocalOnly()
        guard cloudReady else {
            changedDuringCloudLoad = true
            return
        }
        cloud.save(snapshot(), userID: userID) { [weak self] error in
            guard let self, self.userID == userID else { return }
            self.cloudSyncStatus = error.map { "Cloud sync failed: \($0.localizedDescription)" }
                ?? "Synced with Firestore"
        }
    }
}
