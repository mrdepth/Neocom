//
//  BarChart.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct BarChart: View {
    struct Point {
        var timestamp: Date
        var duration: TimeInterval
        var yield: Double
        var waste: Double
    }
    
    var startDate: Date
    var endDate: Date
    var points: [Point]
    var capacity: Double

    private func chart(_ geometry: GeometryProxy, _ max: Double) -> some View {
        let w = CGFloat(endDate.timeIntervalSince(startDate))
        let inset = Double(1.0 / geometry.size.width * w) * 0
        
        let transform = CGAffineTransform(scaleX: geometry.size.width / w, y: geometry.size.height / CGFloat(max)).translatedBy(x: CGFloat(-startDate.timeIntervalSince1970), y: 0)
        
        let yield = Path { path in
            for point in points {
                if point.yield > 0 {
                    path.addRect(CGRect(x: point.timestamp.timeIntervalSince1970,
                                        y: 0,
                                        width: point.duration - inset,
                                        height: point.yield))
                }
            }
        }.transform(transform)
        let waste = Path { path in
            for point in points {
                if point.waste > 0 {
                    path.addRect(CGRect(x: point.timestamp.timeIntervalSince1970,
                                        y: point.yield,
                                        width: point.duration - inset,
                                        height: point.waste))
                }
            }
        }.transform(transform)

        
        return ZStack(alignment: .bottomLeading) {
            yield.foregroundColor(.skyBlueBackground)
            waste.foregroundColor(.red)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .scaleEffect(CGSize(width: 1, height: -1), anchor: .center)
    }
    
    private func grid(_ columns: Int, _ rows: Int) -> some View {
        ZStack {
            HStack(spacing: 0) {
                Divider()
                ForEach(0..<columns) { _ in
                    Spacer()
                    Divider()
                }
            }
            VStack(spacing: 0) {
                Divider()
                ForEach(0..<rows) { _ in
                    Spacer()
                    Divider()
                }
            }
        }
    }
    
    private func progress(_ geometry: GeometryProxy, _ progress: CGFloat) -> some View {
        Rectangle().frame(width: 1).foregroundColor(.skyBlue).offset(x: geometry.size.width * progress, y: 0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @Environment(\.horizontalSizeClass) var horizontalSizeCLass
    
    var body: some View {
        let max = capacity == 0 ? 1 : capacity
        
        let dt = endDate.timeIntervalSince(Date())
        let progress = CGFloat(1 - min(dt / endDate.timeIntervalSince(startDate), 1))
        
        let rows = horizontalSizeCLass == .regular ? 24 : 12
        let cols = 6
        
        return HStack(alignment: .top) {
            Text(UnitFormatter.localizedString(from: max, unit: .none, style: .short)).font(.caption).frame(width: 50, alignment: .trailing)
            VStack {
                grid(rows, cols).aspectRatio(CGFloat(rows) / CGFloat(cols), contentMode: .fit)
                    .overlay(GeometryReader { self.chart($0, max).drawingGroup() })
                    .overlay(GeometryReader { self.progress($0, progress)})
                
                StatusLabel(endDate: endDate)
                    .frame(maxWidth: .infinity)
                    .font(.caption)
                    .padding(.horizontal)
                    .background(ProgressView(progress: Float(progress)).accentColor(.skyBlueBackground))
            }
        }
    }
}

private struct StatusLabel: View {
    var endDate: Date
    @State private var currentTime = Date()
    
    var body: some View {
        let dt = endDate.timeIntervalSince(currentTime)
        
        return Group {
            if dt > 0 {
                Text(TimeIntervalFormatter.localizedString(from: dt, precision: .seconds))
            }
            else {
                Text("Finished: \(TimeIntervalFormatter.localizedString(from: -dt, precision: .seconds)) ago")
            }
        }.onReceive(Timer.publish(every: 1, on: RunLoop.main, in: .default).autoconnect()) { _ in
            self.currentTime = Date()
        }
    }
}

struct BarChart_Previews: PreviewProvider {
    static var previews: some View {
        let points = (-5..<20).map {
            BarChart.Point(timestamp: Date(timeIntervalSinceNow: TimeInterval($0) * 3600 * 2),
                           duration: 3600 * 2,
                           yield: Double(abs($0)),
                           waste: Double(abs($0)).squareRoot())
        }
        let max = points.map{$0.yield + $0.waste}.max() ?? 1

        return BarChart(startDate: points.first!.timestamp, endDate: points.last!.timestamp.addingTimeInterval(3600 * 2), points: points, capacity: max)
    }
}
