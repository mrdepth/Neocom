//
//  TextFieldAlert.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TextFieldAlertAnimationModifier: ViewModifier {
    var isIdentity: Bool
    var cancel: () -> Void
    
    func body(content: Self.Content) -> some View {
        ZStack {
            Color.primary.opacity(isIdentity ? 0.3 : 0).onTapGesture(perform: cancel)
            content.scaleEffect(isIdentity ? 1 : 0.5)
                .opacity(isIdentity ? 1 : 0)
                .animation(isIdentity ? Animation.spring(response: 0.25, dampingFraction: 0.5) : Animation.easeOut(duration: 0.25))
        }.edgesIgnoringSafeArea(.all)
    }
    
}

struct TextFieldAlert: View {
    enum Result {
        case cancel
        case success(String)
    }
    
    var title: LocalizedStringKey
    var placeholder: LocalizedStringKey
    var completion: (Result) -> Void
    @State private var text: String
    @State private var keyboardFrame: CGRect = .null
    
    init(title: LocalizedStringKey, placeholder: LocalizedStringKey, text: String, completion: @escaping (Result) -> Void ) {
        self.title = title
        self.placeholder = placeholder
        self.completion = completion
        _text = State(initialValue: text)
    }
    
    private func updateKeyboardFrame(_ note: Notification) {
        withAnimation {
            keyboardFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .null
        }
    }

    private func hideKeyboard(_ note: Notification) {
        withAnimation {
            keyboardFrame = .null
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack(spacing: 0) {
                    Text(self.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding()
                    TextField(self.placeholder, text: self.$text).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
                    Divider()
                    HStack(spacing: 0) {
                        Button(action: {self.completion(.cancel)}) {
                            Text("Cancel").fontWeight(.medium).frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        Divider()
                        Button(action: {self.completion(.success(self.text))}) {
                            Text("OK").frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }.frame(height: 44)
                }.background(BlurView()).cornerRadius(16).frame(width: min(geometry.size.width * 0.75, 320))
                Spacer().frame(height: self.keyboardFrame.isNull ? 0 : geometry.frame(in: .global).maxY - self.keyboardFrame.minY)
            }
        }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification), perform: updateKeyboardFrame)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification), perform: hideKeyboard)
            .zIndex(1000)
        .transition(.modifier(active: TextFieldAlertAnimationModifier(isIdentity: false) {self.completion(.cancel)},
                              identity: TextFieldAlertAnimationModifier(isIdentity: true) {self.completion(.cancel)}))
    }
}

struct TextFieldAlertTestView: View {
    @State var isPresented = false
    var body: some View {
        Group {
            ZStack {
                Color.white
                Button("Button") {
                    withAnimation {
                        self.isPresented = true
                    }
                }
                if isPresented {
                    TextFieldAlert(title: "Hello, World", placeholder: "Edit", text: "") { result in
                        withAnimation {
                            self.isPresented = false
                        }
                    }
                }
            }
            VStack {
                TextFieldAlert(title: "Rename", placeholder: "Edit", text: "") { result in }
                TextFieldAlert(title: "Rename", placeholder: "Edit", text: "") { result in }
            }
        }
    }
}

struct TextFieldAlert_Previews: PreviewProvider {
    static var previews: some View {
        TextFieldAlertTestView()
    }
}
