//
//  HorizontalSlider.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/18/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

private enum DragState {
    case inactive
    case dragging(Float)
    
    var progress: Float? {
        switch self {
        case .dragging(let translation):
            return translation
        case .inactive:
            return .zero
        }
    }
}

struct HorizontalSlider<Value: BinaryFloatingPoint>: View {
    @Binding var value: Value
    var bounds: ClosedRange<Value>
    var max: Value
    
    
    @GestureState private var dragState = DragState.inactive
    
    init(value: Binding<Value>, in bounds: ClosedRange<Value> = 0...1, max: Value) {
        self._value = value
        self.bounds = bounds
        self.max = max
    }
    
    private var progress: Float {
        get {
            return Float((value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))
//            return (p + dragState.translation).clamped(to: 0...1)
        }
        nonmutating set {
            value = Value(newValue) * (bounds.upperBound - bounds.lowerBound) + bounds.lowerBound
        }
    }
    
    private var maxProgress: Float {
        return Float((max - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ProgressView(progress: self.progress).overlay(Color(.systemBackground).frame(width: 2).offset(x: CGFloat(self.progress) * geometry.size.width, y: 0),
                                                          alignment: .leading)
                .overlay(Color(.systemBackground).opacity(0.5).frame(width: CGFloat(self.maxProgress - self.progress) * geometry.size.width).offset(x: CGFloat(self.progress) * geometry.size.width, y: 0), alignment: .leading)
            .gesture(DragGesture().updating(self.$dragState) { (value, state, _) in
                if case .inactive = state {
                    state = .dragging(self.progress)
                }
            }.onChanged { value in
                let dp = Float(value.translation.width / geometry.size.width)
                self.progress = ((self.dragState.progress ?? self.progress) + dp).clamped(to: 0...self.maxProgress)
            })
        }
    }
}

struct HorizontalSliderTest: View {
    @State private var value: Double = 0.5
    var body: some View {
        HorizontalSlider(value: $value, in: 0...1, max: 0.7).frame(height: 20)
    }
}

struct HorizontalSlider_Previews: PreviewProvider {
    static var previews: some View {
        HorizontalSliderTest()
    }
}
