//
//  Sector.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/20/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct Sector: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool
    var startRadius: CGFloat = 0
    var endRadius: CGFloat = 1
    var animatableData: AnimatablePair<Double, Double> {
        get {
            AnimatablePair(startAngle.animatableData, endAngle.animatableData)
        }
        set {
            startAngle.animatableData = newValue.first
            endAngle.animatableData = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            if startRadius > 0 {
                path.addArc(center: rect.center, radius: min(rect.width, rect.height) / 2 * endRadius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
                path.addArc(center: rect.center, radius: min(rect.width, rect.height) / 2 * startRadius, startAngle: endAngle, endAngle: startAngle, clockwise: !clockwise)
            }
            else {
                path.move(to: rect.center)
                path.addArc(center: rect.center, radius: min(rect.width, rect.height) / 2 * endRadius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
                path.closeSubpath()
            }
        }
    }
}

struct Sector_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Sector(startAngle: Angle(degrees: 0), endAngle: Angle(degrees: -180), clockwise: true)
            Sector(startAngle: Angle(degrees: 0), endAngle: Angle(degrees: -180), clockwise: true, startRadius: 0.5)
            Sector(startAngle: Angle(degrees: 0), endAngle: Angle(degrees: -360), clockwise: true, startRadius: 0.5, endRadius: 0.6)
        }
    }
}
