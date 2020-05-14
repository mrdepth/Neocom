//
//  LineChart.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/28/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct LineChart: View {
    struct Row: Shape, Identifiable {
        func path(in rect: CGRect) -> Path {
            let x = stride(from: xRange.lowerBound, through: xRange.upperBound, by: (xRange.upperBound - xRange.lowerBound) / rect.width * 5)
            let y = x.map{dataSource($0)}
            let points = zip(x,y).map{CGPoint(x: $0, y: $1)}
            let path = UIBezierPath(points: points)
            let bounds = path.bounds
            path.apply(CGAffineTransform(scaleX: 1.0 / bounds.width * rect.width, y: 1.0 / bounds.height * rect.height))//.translatedBy(-bounds.origin))
            return Path(path.cgPath)
        }
        
        var id: AnyHashable
        var xRange: ClosedRange<CGFloat>
        var yRange: ClosedRange<CGFloat>
        var color: Color
        var dataSource: (CGFloat) -> CGFloat
    }
    
    var rows: [Row]
    
    
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
    
    private var yTitles: some View {
        let y = rows.map{$0.yRange.upperBound}.max() ?? 1
        let dy = y / 6
        return VStack(alignment: .trailing) {
            ForEach(stride(from: 0, to: y, by: dy).reversed(), id: \.self) { i in
                Text("\(UnitFormatter.localizedString(from: Double(i), unit: .none, style: .short))").frame(maxHeight: .infinity, alignment: .bottom)
            }
        }.font(.caption).frame(width: 30, alignment: .trailing)
    }

    private var xTitles: some View {
        let x = rows.map{$0.xRange.upperBound}.max() ?? 1
        let dx = x / 6
        return HStack {
            ForEach(Array(stride(from: 0, to: x, by: dx)), id: \.self) { i in
                Text("\(UnitFormatter.localizedString(from: Double(i), unit: .meter, style: .short))").frame(maxWidth: .infinity, alignment: .leading)
            }
        }.font(.caption).frame(height: 25, alignment: .top)
    }

    private var lines: some View {
        let h = rows.map{$0.yRange.upperBound}.max() ?? 0
        let w = rows.map{$0.xRange.upperBound}.max() ?? 0
        return GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                ForEach(self.rows) { row in
                    row.stroke(row.color)
                        .frame(width: w > 0 ? geometry.size.width * row.xRange.upperBound / w : 0,
                               height: h > 0 ? geometry.size.height * row.yRange.upperBound / h : 0)
                }
            }
        }
    }
    
    var body: some View {
        HStack {
            grid(12, 6).aspectRatio(12.0 / 6.0, contentMode: .fit)
                .overlay(yTitles.offset(x: -35, y: 0), alignment: .leading)
                .overlay(xTitles.offset(x: 0, y: 30), alignment: .bottom)
                .overlay(lines)
                .padding(.bottom, 30)
        }.padding(.leading, 35)
            
    }
}

struct LineChartTestView: View {
    @State var rows: [LineChart.Row] = {
        let row = LineChart.Row(id: AnyHashable(0),
                                xRange: 0...CGFloat(Angle(degrees: 360).radians),
                                yRange: 0...1,
                                color: .red) { (x) -> CGFloat in sin(x) + 1 }
        return [row]
    }()
    
    
    var body: some View {
        VStack {
            LineChart(rows: rows)
            Button(action: {
                withAnimation {
                if self.rows.count == 1 {
                    let row = LineChart.Row(id: AnyHashable(1),
                                            xRange: 0...CGFloat(Angle(degrees: 360 + 180).radians),
                                            yRange: 0...2,
                                            color: .blue) { (x) -> CGFloat in (cos(x) + 1) * 2 }
                    self.rows = [self.rows[0], row]
                }
                else {
                    self.rows = [self.rows[0]]
                }
                }
            }) {
                Text("Button")
            }
        }
    }
}

struct LineChart_Previews: PreviewProvider {
    static var previews: some View {
        LineChartTestView()
    }
}
