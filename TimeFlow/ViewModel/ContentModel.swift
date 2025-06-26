//
//  ContentModel.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/11/25.
//

import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn


@Observable
class ContentModel {
    
    var newUser = true //at first have them go through on boarding process
    
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
    
    func onBoardingComplete() {
        newUser = false
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
    
    @MainActor
    func googleSignIn(windowScene: UIWindowScene?) async throws {
        guard let rootVC = windowScene?.windows.first?.rootViewController else {
            throw URLError(.badServerResponse)
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = result.user.accessToken.tokenString
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        let authResult = try await Auth.auth().signIn(with: credential)
        let user = authResult.user
        
        if authResult.additionalUserInfo?.isNewUser == true {
            let doc = db.collection("users").document(user.uid)
            
            try await doc.setData([
                "email": user.email ?? "",
                "name": user.displayName ?? "",
                "account_created": DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium),
                "agreedToEULA": false //can maybe make true because the terms and conditions will be linked below during signup
            ])
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
