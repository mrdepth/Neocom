//
//  LineChart.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/28/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct LineChart: View {
    
    
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
        VStack(alignment: .trailing) {
            ForEach(stride(from: 0, to: 6, by: 1).reversed(), id: \.self) {
                Text("\($0)").frame(maxHeight: .infinity, alignment: .bottom)
            }
        }.font(.caption).frame(width: 30, alignment: .trailing)
    }
    
    private func line() {
        
    }
    
    var body: some View {
        HStack {
            grid(12, 6).aspectRatio(12.0 / 6.0, contentMode: .fit)
                .overlay(yTitles.offset(x: -35, y: 0), alignment: .leading)
        }.padding(.leading, 35)
            
    }
}

struct LineChart_Previews: PreviewProvider {
    static var previews: some View {
        LineChart()
    }
}
