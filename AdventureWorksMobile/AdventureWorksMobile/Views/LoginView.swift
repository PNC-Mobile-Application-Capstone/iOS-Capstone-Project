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
        ScrollView {
            VStack(spacing: 32) {
                header

                VStack(alignment: .leading, spacing: 24) {

                    if let message = authStatus.sessionMessage {
                        Label(message, systemImage: "info.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("sessionMessage")
                    }

                    field("Username") {
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
                .disabled(viewModel.isBusy)
            }
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

        private let authService: any AuthServicing

        init(authService: (any AuthServicing)? = nil) {
            self.authService = authService ?? AuthService.shared
        }

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
            errorMessage = ""
            isBusy = true
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
