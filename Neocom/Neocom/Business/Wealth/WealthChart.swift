//
//  WealthChart.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/20/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

private struct WealthTitlePreferenceKey: PreferenceKey {
    static func reduce(value: inout [Int : CGSize], nextValue: () -> [Int : CGSize]) {
        value.merge(nextValue()) {a, _ in a}
    }
    
    static var defaultValue: [Int: CGSize] = [:]
}

private struct WealthTitleAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[.trailing]
    }
}

fileprivate struct AnimatableISKModifier: AnimatableModifier {
    var isk: Double
    
    var animatableData: Double {
        get {
            isk
        }
        set {
            isk = newValue
        }
    }
    
    func body(content: Content) -> some View {
        VStack {
            content
            Text("\(UnitFormatter.localizedString(from: isk, unit: .isk, style: .short))")
        }
    }
}

struct WealthSegment: View {
    var startAngle: Angle
    var endAngle: Angle
    var isk: Double
    
    var body: some View {
        ZStack {
            Sector(startAngle: -startAngle, endAngle: -endAngle, clockwise: true, startRadius: 0.6, endRadius: 1).foregroundColor(.accentColor)
            Sector(startAngle: -startAngle, endAngle: -endAngle, clockwise: true, startRadius: 0.4, endRadius: 0.6).foregroundColor(.accentColor).opacity(0.75)
        }
    }
}

struct WealthTitle: View {
    var angle: Angle
    var title: Text
    var isk: Double
    
    var body: some View {
        let label = title.modifier(AnimatableISKModifier(isk: isk))
            .padding(4)
            .background(Color(.quaternarySystemFill).cornerRadius(8))
            .foregroundColor(.accentColor)
            .sizePreference(WealthTitle.self)
            .opacity(isk > 0.0 ? 1.0 : 0.0)
            .font(.footnote)
            .rotationEffect(angle)
            .alignmentGuide(HorizontalAlignment(WealthTitleAlignmentID.self), computeValue: {
                $0[HorizontalAlignment.center] - sqrt($0.width * $0.width + $0.height * $0.height) / 2
            })
        return Color.clear.overlay(label, alignment: Alignment(horizontal: HorizontalAlignment(WealthTitleAlignmentID.self), vertical: .center))
            .rotationEffect(-angle)
    }
}


struct WealthChart: View {
    struct Section {
        var title: Text
        var amount: Double
        var color: Color
    }
    @State private var animate = true
    @State private var titleSizes: [CGSize] = []
    
    var sections: [Section]
    
    var body: some View {
        let total = sections.map{$0.amount}.reduce(0, +)
        var angles: [Angle]
        
        if total > 0 {
            angles = sections.map{$0.amount}.reduce(into: [Angle.zero]) { (angles, isk) in
                angles.append(angles.last! + Angle(degrees: isk / total * 360))
            }
            angles.append(Angle(degrees: 360))
        }
        else {
            angles = Array(repeating: .zero, count: sections.count + 1)
        }
        
        func views(_ geometry: GeometryProxy) -> some View {
            let width = (self.titleSizes.map{$0.width}.max() ?? 0) / 2
            let height = (self.titleSizes.map{$0.height}.max() ?? 0) / 2
            let r = sqrt(width * width + height * height)
            let R = geometry.size.width + r + 4
            let c = 2 * r
            let t = Angle(radians: Double(asin(c / (2 * R)) * 2))
            
            var result = sections.indices.map { i in
                (angles[i] + angles[i + 1]) / 2
            }
            let indices = sections.indices.filter{sections[$0].amount > 0}

            for _ in 0..<10  {
                var finished = true
                for i in indices.indices.dropFirst() {
                    let d = result[indices[i]] - result[indices[i - 1]]
                    if d < t {
                        result[indices[i - 1]] -= d / 2
                        result[indices[i]] += d / 2
                        finished = false
                    }
                }
                if finished {
                    break
                }
            }
            
            let views = self.sections.enumerated().map { (i, section) in
                (segment: WealthSegment(startAngle: angles[i], endAngle: angles[i + 1], isk: section.amount).accentColor(section.color),
                 title: WealthTitle(angle: result[i], title: section.title, isk: section.amount).accentColor(section.color))
            }
            
            return ForEach(views.indices) { i in
                views[i].segment
                views[i].title
            }
            
        }
        
        return ZStack {
            GeometryReader { geometry in
                views(geometry)
                    .overlay(GeometryReader { geometry in
                    ZStack {
                        Text("Total").modifier(AnimatableISKModifier(isk: total)).lineLimit(1).minimumScaleFactor(0.5).font(.footnote)
                    }.frame(width: geometry.size.width * 0.3, height: geometry.size.height * 0.3)
                })
            }
        }
        .animation(.easeOut(duration: 1)).aspectRatio(1, contentMode: .fit)
        .padding(80)
        .onSizeChange(WealthTitle.self) { self.titleSizes = $0}
    }
}

struct WealthChart_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
//            List {
                WealthChart(sections: [
                    WealthChart.Section(title: Text("Account"), amount: 26, color: .blue),
                    WealthChart.Section(title: Text("Blueprints"), amount: 2000, color: .purple),
                    WealthChart.Section(title: Text("Implats"), amount: 108, color: .green),
                    WealthChart.Section(title: Text("Assets"), amount: 18000, color: .red),
                ])
//            }.listStyle(GroupedListStyle())
        }
    }
}
