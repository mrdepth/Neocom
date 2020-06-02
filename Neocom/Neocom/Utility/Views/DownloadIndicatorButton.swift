//
//  DownloadIndicatorButton.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/15/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct DownloadIndicatorButton: View {
    var progress: Progress
    var onCancel: () -> Void
    @State private var fractionCompleted: Double = 0
    
    init(progress: Progress, onCancel: @escaping () -> Void) {
        self.progress = progress
        self.onCancel = onCancel
        _fractionCompleted = State(initialValue: progress.fractionCompleted)
    }
    
    var body: some View {
        Button(action: onCancel) {
            Circle().stroke(lineWidth: 2)
                .foregroundColor(Color(.systemFill))
                .overlay(Rectangle().frame(width: 8, height: 8))
                .overlay(Circle().trim(from: 0, to: CGFloat(fractionCompleted)).stroke(lineWidth: 2).rotation(.degrees(-90)))
        }
        .frame(width: 29, height: 29)
        .onReceive(progress.publisher(for: \.fractionCompleted).receive(on: RunLoop.main)) {
            self.fractionCompleted = $0
        }
        .animation(.easeOut)
        .transition(.scale(scale: 0.1))
    }
}

struct DownloadIndicatorButtonTest: View {
    @State private var flag = false
    
    var body: some View {
        VStack {
            if !flag {
                DownloadIndicatorButton(progress: Progress(totalUnitCount: 5)) {
                    withAnimation {
                        self.flag = true
                    }
                }
            }
        }
    }
}

struct DownloadIndicatorButton_Previews: PreviewProvider {
    static var previews: some View {
        DownloadIndicatorButtonTest()
    }
}
