//
//  LoadingProgressView.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/11/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

class ProgressWrapper: ObservableObject {
    let progress: Progress
    @Published var fractionCompleted: Float
    
    private var subscription: AnyCancellable?
    
    init(_ progress: Progress) {
        self.progress = progress
        fractionCompleted = Float(progress.fractionCompleted)
        
        subscription = progress.publisher(for: \.fractionCompleted).receive(on: RunLoop.main).sink { [weak self] _ in
            self?.fractionCompleted = Float(progress.fractionCompleted)
        }
    }
}

struct LoadingProgressView: View {
    @ObservedObject private var progress: ProgressWrapper
    init(progress: Progress) {
        _progress = ObservedObject(initialValue: ProgressWrapper(progress))
    }
    
    var body: some View {
        ProgressView(progress: progress.fractionCompleted, progressTrackColor: .clear, borderColor: .clear)
            .frame(height: 4)
    }
}

struct LoadingProgressView_Previews: PreviewProvider {
    static var previews: some View {
        let progress = Progress(totalUnitCount: 2)
        progress.completedUnitCount = 1
        return LoadingProgressView(progress: progress)
    }
}
