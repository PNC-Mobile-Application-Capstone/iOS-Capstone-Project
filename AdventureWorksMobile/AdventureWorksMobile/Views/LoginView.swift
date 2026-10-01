//
//  LoginView.swift
//
//
//  Created by Nathan Bergman on 9/20/26.
//
import SwiftUI

struct LoginView: View {

    // Note: this is @State, not @StateObject, because ViewModel below is
    // an @Observable class (the newer Observation framework), not an
    // ObservableObject. @State works for both value types and @Observable
    // reference types; SwiftUI only re-renders when a property the body
    // actually reads changes, rather than on every change to the object
    // (which is how @Published/ObservableObject behaves).
    @State private var viewModel = ViewModel()
    @EnvironmentObject var authStatus: AuthStatus


    var body: some View {
        VStack {
            Text("Login")
                .font(Font.largeTitle.bold())

            TextField("Username", text: $viewModel.credentials.username)
                .accessibilityIdentifier("usernameField")
            SecureField("Password", text: $viewModel.credentials.password)
                .accessibilityIdentifier("passwordField")

            if viewModel.isBusy {
                ProgressView()
            }

            Button("Log in") {
                Task {
                    let response = await viewModel.login()
                    if let resp = response {
                        // On success, this is what actually flips the app
                        // over to the logged-in state and persists the new
                        // tokens to the Keychain (see AuthStatus.logIn).
                        guard resp.success,
                              authStatus.logIn(accessToken: resp.accessToken,
                                               refreshToken: resp.refreshToken) else {
                            viewModel.errorMessage = "The server did not return a valid session. Please try again."
                            return
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.loginDisabled)
            .accessibilityIdentifier("loginButton")

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(Color.red)
            }

            Spacer()

        }
        .padding(20)
        .autocapitalization(.none)
        .disabled(viewModel.isBusy)
    }
}

extension LoginView {

    // @Observable is a macro (from the Observation framework) that
    // expands at compile time to make every stored property trackable by
    // SwiftUI, without needing @Published on each one and without
    // conforming to ObservableObject. SwiftUI only re-renders views for
    // the specific properties they actually read in `body`, which is more
    // efficient than ObservableObject's "any change re-renders every
    // observer" behavior.
    @MainActor
    @Observable
    class ViewModel {

        var credentials = LoginModel()
        var isBusy = false

        var loginDisabled: Bool {
            credentials.username.isEmpty || credentials.password.isEmpty
        }

        var errorMessage: String = ""

        /// Calls AuthService.login and reports back a LoginResponse (or
        /// nil, with errorMessage set, if the call throws). Does not
        /// itself touch AuthStatus/the Keychain; the caller (LoginView's
        /// button action) is responsible for calling
        /// authStatus.logIn with the result.
        func login() async -> LoginResponse? {
            isBusy = true

            do {
                let result = try await AuthService.shared.login(credentials: credentials)
                isBusy = false

                if !result.success {
                    errorMessage = "Invalid username/password combination"
                }
                return result
            }
            catch {
                errorMessage = error.localizedDescription

            }
            isBusy = false
            return nil
        }


    }

}

#Preview {
    LoginView()
        .environmentObject(AuthStatus())
}
