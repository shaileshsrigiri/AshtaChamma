import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var showPassword = false
    @State private var errorAlert = false

    var body: some View {
        VStack(spacing: 20) {
            // Title
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.system(size: 32, weight: .bold))
                Text("Join Ashta Chamma")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 10)

            // Username Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)

                TextField("Enter your username", text: $username)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)

                TextField("Enter your email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)

                HStack {
                    if showPassword {
                        TextField("Enter password", text: $password)
                            .autocapitalization(.none)
                    } else {
                        SecureField("Enter password", text: $password)
                    }
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)

                SecureField("Confirm password", text: $confirmPassword)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            // Sign Up Button
            Button(action: signUp) {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(8)
                } else {
                    Text("Sign Up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .disabled(authViewModel.isLoading)

            // Login Link
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                NavigationLink("Log In") {
                    LoginView()
                        .navigationBarBackButtonHidden(true)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
        }
        .padding(20)
        .alert("Error", isPresented: $errorAlert) {
            Button("OK") { }
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred")
        }
        .onChange(of: authViewModel.errorMessage) { newValue in
            if newValue != nil {
                errorAlert = true
            }
        }
    }

    private func signUp() {
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty else {
            authViewModel.errorMessage = "Please fill in all fields"
            errorAlert = true
            return
        }

        guard password == confirmPassword else {
            authViewModel.errorMessage = "Passwords do not match"
            errorAlert = true
            return
        }

        guard password.count >= 6 else {
            authViewModel.errorMessage = "Password must be at least 6 characters"
            errorAlert = true
            return
        }

        authViewModel.signUp(email: email, password: password, username: username)
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
