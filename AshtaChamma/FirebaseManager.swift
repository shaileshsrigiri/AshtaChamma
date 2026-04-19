import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager: NSObject {
    static let shared = FirebaseManager()

    override init() {
        super.init()
        FirebaseApp.configure()
    }

    // MARK: - Authentication

    func signUp(email: String, password: String, username: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user else {
                completion(.failure(NSError(domain: "Auth", code: -1, userInfo: nil)))
                return
            }

            // Save user profile to Firestore
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "username": username,
                "email": email,
                "wins": 0,
                "losses": 0,
                "createdAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(user.uid))
                }
            }
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user else {
                completion(.failure(NSError(domain: "Auth", code: -1, userInfo: nil)))
                return
            }

            completion(.success(user.uid))
        }
    }

    func logout() throws {
        try Auth.auth().signOut()
    }

    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }

    // MARK: - User Profile

    func getUserProfile(uid: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let document = document, document.exists, let data = document.data() else {
                completion(.failure(NSError(domain: "Firestore", code: -1, userInfo: nil)))
                return
            }

            completion(.success(data))
        }
    }

    // MARK: - Game Operations

    func createGame(players: [String], completion: @escaping (Result<String, Error>) -> Void) {
        let db = Firestore.firestore()
        let gameRef = db.collection("games").document()
        let gameId = gameRef.documentID

        var playersData: [String: [String: Any]] = [:]
        for playerId in players {
            playersData[playerId] = [
                "ready": false,
                "joinedAt": FieldValue.serverTimestamp()
            ]
        }

        gameRef.setData([
            "gameId": gameId,
            "players": playersData,
            "status": "waiting",
            "createdAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(gameId))
            }
        }
    }

    func joinGame(gameId: String, playerId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("games").document(gameId).updateData([
            "players.\(playerId)": [
                "ready": false,
                "joinedAt": FieldValue.serverTimestamp()
            ]
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }

    func getGame(gameId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("games").document(gameId).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let document = document, document.exists, let data = document.data() else {
                completion(.failure(NSError(domain: "Firestore", code: -1, userInfo: nil)))
                return
            }

            completion(.success(data))
        }
    }

    func updateGameState(gameId: String, gameState: [String: Any], completion: @escaping (Result<Bool, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("games").document(gameId).updateData([
            "gameState": gameState
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }

    func listenToGame(gameId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) -> ListenerRegistration {
        let db = Firestore.firestore()
        return db.collection("games").document(gameId).addSnapshotListener { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let document = document, document.exists, let data = document.data() else {
                completion(.failure(NSError(domain: "Firestore", code: -1, userInfo: nil)))
                return
            }

            completion(.success(data))
        }
    }
}
