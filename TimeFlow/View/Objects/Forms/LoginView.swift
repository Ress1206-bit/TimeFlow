//
//  LoginView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/11/25.
//

import SwiftUI
import FirebaseAuth

struct LoginForm: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var formShowing: Bool
    
    @State private var showAlert: Bool = false
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isSecured: Bool = true
    
    var body: some View {
        VStack {
            Text("Sign In")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 15) {
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .textInputAutocapitalization(.never)
                
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
            
            Button(action: signIn) {
                HStack {
                    Spacer()
                    Text("Sign In")
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
            Alert(title: Text("Error"), message: Text("Incorrect email or password."), dismissButton: .default(Text("OK")))
        }
    }
    
    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if error == nil {
                formShowing = false
            } else {
                errorMessage = error?.localizedDescription
                showAlert = true
            }
        }
    }
}

#Preview {
    LoginForm(formShowing: Binding.constant(true))
}
