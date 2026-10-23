//
//  LoginView.swift
//
//
import SwiftUI

struct LoginView: View {

    // @State, not @StateObject, because ViewModel uses @Observable instead of ObservableObject.
    @State private var viewModel = ViewModel()
    @EnvironmentObject var authStatus: AuthStatus


    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header

                VStack(alignment: .leading, spacing: 24) {

                    // Shown after a session expires.
                    if let message = authStatus.sessionMessage {
                        Label(message, systemImage: "info.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("sessionMessage")
                    }

                    // field() wraps each input with a label and shared styling.
                    field("Username") {
                        // $ makes a two-way binding to the view model.
                        TextField("Enter your username", text: $viewModel.credentials.username)
                            .textContentType(.username)
                            .accessibilityIdentifier("usernameField")
                    }

                    field("Password") {
                        SecureField("Enter your password", text: $viewModel.credentials.password)
                            .textContentType(.password)
                            .accessibilityIdentifier("passwordField")
                    }

                    if !viewModel.errorMessage.isEmpty {
                        Label(viewModel.errorMessage, systemImage: "exclamationmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("loginErrorMessage")
                    }

                    Button(action: signIn) {
                        HStack(spacing: 10) {
                            if viewModel.isBusy { ProgressView().tint(.white) }
                            Text(viewModel.isBusy ? "Signing in…" : "Sign in")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                    .tint(.green)
                    .disabled(viewModel.loginDisabled)
                    .accessibilityIdentifier("loginButton")
                }
                .padding(24)
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 12))
                // Lock the form while signing in.
                .disabled(viewModel.isBusy)
            }
            // Cap the width on iPad, then center it.
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .padding([.horizontal, .bottom], 24)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(spacing: 14) {
            Image(systemName: "bicycle")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 80, height: 80)
                .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
                .accessibilityHidden(true)

            Text("Adventure Works")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.top, 32)
    }

    // Generic helper. @ViewBuilder lets the caller pass any view in the closure.
    private func field<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.medium))

            content()
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(14)
                .background(Color(uiColor: .tertiarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func signIn() {
        // Task runs the async login from a button tap. Tokens are saved only on success.
        Task {
            if let response = await viewModel.login() {
                guard response.success,
                      authStatus.logIn(accessToken: response.accessToken,
                                       refreshToken: response.refreshToken) else {
                    viewModel.errorMessage = "Unable to sign in. Please try again."
                    return
                }
            }
        }
    }

}

extension LoginView {

    // @Observable tracks each property, so views redraw only when a property they read changes.
    @MainActor
    @Observable
    class ViewModel {

        private let authService: any AuthServicing

        // Tests pass a stub. The app uses the shared AuthService.
        init(authService: (any AuthServicing)? = nil) {
            self.authService = authService ?? AuthService.shared
        }

        var credentials = LoginModel()
        var isBusy = false

        var loginDisabled: Bool {
            credentials.username.isEmpty || credentials.password.isEmpty
        }

        var errorMessage: String = ""

        /// Calls AuthService.login. Returns nil and sets errorMessage on failure. The caller saves the tokens.
        func login() async -> LoginResponse? {
            errorMessage = ""
            isBusy = true
            // defer turns the spinner off however the function exits.
            defer { isBusy = false }

            do {
                let result = try await authService.login(credentials: credentials)

                if !result.success {
                    errorMessage = "Incorrect username or password."
                    return nil
                }
                return result
            }
            catch NetworkError.unauthorized {
                errorMessage = "Incorrect username or password."
            }
            catch {
                errorMessage = "Unable to sign in. Please try again."
            }
            return nil
        }


    }

}

#Preview {
    LoginView()
        .environmentObject(AuthStatus())
}
