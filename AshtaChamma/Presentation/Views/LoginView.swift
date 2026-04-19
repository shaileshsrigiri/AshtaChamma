import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorAlert = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Back Button
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(.bottom, 10)

            // Title
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.system(size: 32, weight: .bold))
                Text("Log in to your account")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 10)

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

            // Login Button
            Button(action: login) {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(8)
                } else {
                    Text("Log In")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .disabled(authViewModel.isLoading)

            // Sign Up Link
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                NavigationLink("Sign Up") {
                    SignUpView()
                        .navigationBarBackButtonHidden(true)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
        }
        .padding(20)
        .navigationBarBackButtonHidden(true)
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

    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            authViewModel.errorMessage = "Please fill in all fields"
            errorAlert = true
            return
        }

        authViewModel.login(email: email, password: password)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
