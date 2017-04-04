///
/// FirebaseManager.swift
///

import Alamofire
import Firebase
import FirebaseDatabase
import FirebaseStorage
import Foundation

typealias GameID = String

final class FirebaseManager {
    
    static let shared = FirebaseManager()
    
    static private let db = FIRDatabase.database().reference()
    
    private let storage = FIRStorage.storage(url: "gs://highwaybingo.appspot.com").reference()
    
    private let userId = UserDefaults.standard.string(forKey: "uid")!
    
    enum Child {
        static var users: FIRDatabaseReference { return db.child("users") }
        static var games: FIRDatabaseReference { return db.child("games") }
    }
    
    private init() {}
  
    func createOrUpdate(_ user: FIRUser) {
        let name = user.displayName ?? "Anonymous"
        let params = ["name":name]
        
        if let imageUrl = user.photoURL {
            getPhoto(url: imageUrl) { image in
                if let image = image {
                    let location = self.storage.child("images/\(self.userId).jpg")
                    self.save(image, at: location, params: params)
                    return
                }
            }
        }
        Child.users.child(userId).setValue(params)
    }
    
    private func save(_ image: UIImage, at location: FIRStorageReference, params: [String : String]) {
        guard let data = UIImageJPEGRepresentation(image, 0.8) else {
            Child.users.child(userId).setValue(userId)
            return
        }
        
        let metaData = FIRStorageMetadata()
        metaData.contentType = "image/jpg"
        
        location.put(data, metadata: metaData) { (metadata, error) in
            if let imageUrl = metadata?.downloadURL() {
                let paramsWithImage = params += ["imageUrl" : String(describing: imageUrl)]
                Child.users.child(self.userId).setValue(paramsWithImage)
            } else {
                print("FirebaseManager -> error saving photo")
                Child.users.child(self.userId).setValue(params)
            }
        }
    }
    
    func create(_ game: Game) -> GameID {
        let game = Child.games.childByAutoId()
        game.setValue(["leader":userId])
        return game.key
    }
    
    func sendInvitations(for: GameID, to: [FacebookUser]) {
        
    }
    
    private func getPhoto(url: URL, handler: @escaping (UIImage?) -> ()) {
        Alamofire.request(url).responseImage { response in
            let image = response.result.value
            handler(image)
        }
    }
}
