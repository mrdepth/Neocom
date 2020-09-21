//
//  AuthorizationAppleIDButton.swift
//  Neocom
//
//  Created by Artem Shimanski on 7/22/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import AuthenticationServices

struct AuthorizationAppleIDButton: UIViewRepresentable {
    var completion: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    func makeUIView(context: Context) -> AuthorizationAppleIDButtonWrapper {
        AuthorizationAppleIDButtonWrapper(authorizationButtonType: .signIn, authorizationButtonStyle: colorScheme == .dark ? .white : .black, completion: completion)
    }
    
    func updateUIView(_ uiView: AuthorizationAppleIDButtonWrapper, context: Context) {
        uiView.completion = completion
    }
}

class AuthorizationAppleIDButtonWrapper: ASAuthorizationAppleIDButton, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var completion: () -> Void
    
    init(authorizationButtonType type: ASAuthorizationAppleIDButton.ButtonType, authorizationButtonStyle style: ASAuthorizationAppleIDButton.Style, completion: @escaping () -> Void) {
        self.completion = completion
        super.init(authorizationButtonType: type, authorizationButtonStyle: style)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        addTarget(self, action: #selector(onPress), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        DispatchQueue.main.async {
            self.completion()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error)
    }
}

struct AuthorizationAppleIDView: View {
    @State private var isAlertPresented = false
    var body: some View {
        AuthorizationAppleIDButton {
            self.isAlertPresented = true
        }.alert(isPresented: $isAlertPresented) {
            Alert(title: Text("No characters found"), message: Text("Please use another authentication method"), dismissButton: .cancel(Text("Ok")))
        }
    }
}

struct AuthorizationAppleIDButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            AuthorizationAppleIDButton() {}
        }
    }
}
