import Foundation
import FirebaseFirestore

// One private Firestore document per Firebase Authentication UID.
// The app keeps its existing local TripStorage as its offline backup.
final class FirestoreTripStore {
    private let database = Firestore.firestore()

    func load(userID: String, completion: @escaping (Result<TripSnapshot?, Error>) -> Void) {
        database.collection("users").document(userID).getDocument { document, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let payload = document?.data()?["snapshotJSON"] as? String else {
                DispatchQueue.main.async { completion(.success(nil)) }
                return
            }
            do {
                let snapshot = try JSONDecoder().decode(TripSnapshot.self, from: Data(payload.utf8))
                DispatchQueue.main.async { completion(.success(snapshot)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func save(_ snapshot: TripSnapshot, userID: String, completion: @escaping (Error?) -> Void) {
        do {
            var portable = snapshot
            // The active GPS trip is device-specific: never restore monitoring on another phone.
            portable.activeTrip = nil
            let data = try JSONEncoder().encode(portable)
            guard let json = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileWriteInapplicableStringEncoding)
            }
            database.collection("users").document(userID).setData([
                "snapshotJSON": json,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                DispatchQueue.main.async { completion(error) }
            }
        } catch {
            DispatchQueue.main.async { completion(error) }
        }
    }

    func saveProfile(userID: String, displayName: String, email: String) {
        database.collection("users").document(userID).setData([
            "displayName": displayName,
            "email": email,
            "profileUpdatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
}
