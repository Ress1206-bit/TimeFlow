//
//  CreateAccountView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/11/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateAccountForm: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var formShowing: Bool
    
    @State private var showAlert: Bool = false
    
    @State private var email: String = ""
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isSecured: Bool = true
    
    var body: some View {
        VStack {
            // Title
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            // Form fields
            VStack(alignment: .leading, spacing: 15) {
                TextField("Full Name", text: $name)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .textInputAutocapitalization(.never)
                
                TextField("Username", text: $username)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .textInputAutocapitalization(.never)
                    .textCase(.lowercase)
                
                ZStack(alignment: .trailing) {
                    if isSecured {
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .textInputAutocapitalization(.never)
                    } else {
                        TextField("Password", text: $password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .textInputAutocapitalization(.never)
                    }
                    
                    Button(action: {
                        isSecured.toggle()
                    }) {
                        Image(systemName: self.isSecured ? "eye.slash" : "eye")
                            .accentColor(.gray)
                            .padding(.trailing, 16)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Create account button
            Button(action: createAccount) {
                HStack {
                    Spacer()
                    Text("Create Account")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.top, 60)
        .background(
            LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .light ? .white : .black,
                        .blue.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea())
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
    }
    
    func createAccount() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = error.localizedDescription
                    showAlert = true
                } else if let user = result?.user {
                    // Add the user to Firestore
                    let db = Firestore.firestore()
                    
                    db.collection("users").document(user.uid).setData([
                        "username": username,
                        "email": email,
                        "name": name,
                        "profile_picture_url": "",
                        "account_created": Date(),
                        "post_ids": [],
                        "agreedToEULA": false
                    ]) { error in
                        if let error = error {
                            errorMessage = error.localizedDescription
                            showAlert = true
                        } else {
                            formShowing = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CreateAccountForm(formShowing: Binding.constant(true))
}
