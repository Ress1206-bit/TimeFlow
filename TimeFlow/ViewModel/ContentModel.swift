//
//  ContentModel.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/11/25.
//

import Foundation
import Firebase
import FirebaseAuth


@Observable
class ContentModel {
    
    var loggedIn = false
    var agreedToEULA = true //give them the benefit of the doubt haha :)
    
    private var showAlert: Bool = false
    
    private var email: String = ""
    private var password: String = ""
    private var isSecured: Bool = true
    
    let db = Firestore.firestore()
    
    func checkLogin() {
        loggedIn = Auth.auth().currentUser == nil ? false : true
    }
    
    func getUserData() {
        
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if error == nil {
                print("Sign in Complete")
            } else {
                //let errorMessage = error?.localizedDescription
                print("Error: Show Alert")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        }
        catch {
            print("error signing out")
        }
    }
    
    @MainActor
    func createAccount(email: String, name: String, password: String) async throws {
        
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        try await Firestore.firestore()
            .collection("users")
            .document(result.user.uid)
            .setData([
                "email": email,
                "name": name,
                "account_created": DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium),
                "agreedToEULA": false //can maybe make true because the terms and conditions will be linked below during signup
            ])
    }
    
    
    func checkIfEmailExists(email: String, completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: "TemporaryPassword123") { authResult, error in
            if let error = error as NSError? {
                // Check if the error indicates the email is already in use
                if error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    completion(true, nil) // Email exists
                } else {
                    completion(false, error) // Other error (e.g., invalid email, network issue)
                }
            } else {
                // User was created successfully, but we don't want a new user
                // Delete the temporary user to avoid cluttering Firebase
                if let user = authResult?.user {
                    user.delete { deletionError in
                        if let deletionError = deletionError {
                            print("Failed to delete temporary user: \(deletionError.localizedDescription)")
                        }
                        completion(false, nil) // Email does not exist
                    }
                } else {
                    completion(false, nil) // Email does not exist
                }
            }
        }
    }
    
}
