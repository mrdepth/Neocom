//
//  FinishedView.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/30/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct FinishedView: View {
    @Binding var isPresented: Bool

    struct CheckmarkModifier: ViewModifier {
        var isIdentity = false
        @Binding var isPresented: Bool
        var checkmark: some View {
            Path { path in
                path.addLines([CGPoint(x: 0, y: 15),
                               CGPoint(x: 14, y: 32),
                               CGPoint(x: 32, y: 4)])
            }.trim(from: 0, to: isIdentity ? 1.0 : 0.0)
                .stroke(Color.secondary, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 32, height: 32)
        }

        func body(content: Content) -> some View {
            BlurView()
                .frame(width: 128, height: 128)
                .cornerRadius(16)
                .overlay(checkmark.animation(.easeOut))
                .onAppear {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            self.isPresented.toggle()
                        }
                    }
            }

        }
    }
    
    var checkmark = Path { path in
        path.addLines([CGPoint(x: 0, y: 15),
                       CGPoint(x: 14, y: 32),
                       CGPoint(x: 32, y: 4)])
    }
    

    
    var body: some View {
        BlurView().frame(width: 128, height: 128)
            .transition(.asymmetric(insertion: AnyTransition.modifier(active: CheckmarkModifier(isIdentity: false, isPresented: $isPresented),
                                                                      identity: CheckmarkModifier(isIdentity: true, isPresented: $isPresented)),
                                    removal: .opacity))
    }
}

private struct FinishedViewTest: View {
    @State var isFinished = false
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(0..<20, id: \.self) { _ in
                    Group {
                        Color.secondary
                        Color.white
                    }
                }
            }
            if isFinished {
                FinishedView(isPresented: $isFinished)
            }
            Button("Start") {
                withAnimation {
                    self.isFinished.toggle()
                }
            }.zIndex(2)
        }//.overlay(FinishedView(isPresented: $isFinished).animation(.linear).transition(.opacity))
    }
}

struct FinishedView_Previews: PreviewProvider {
    static var previews: some View {
        FinishedViewTest()
    }
}
