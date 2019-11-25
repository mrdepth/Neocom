//
//  ProgressView.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct ProgressView: View {
    var progress: Float
    var body: some View {
        GeometryReader { geometry in
            Rectangle().fill(Color(UIColor.systemGray4))
                .frame(width: geometry.size.width * CGFloat(self.progress), alignment: .leading)
                .offset(x: -geometry.size.width * CGFloat(1.0 - self.progress) / 2, y: 0)
        }.overlay(Rectangle().strokeBorder(Color(UIColor.systemGray2), lineWidth: 1, antialiased: false))
    }
}

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 10) {
            Text("70%").padding(.horizontal).background(ProgressView(progress: 0.7)).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.light)
            Text("70%").padding(.horizontal).background(ProgressView(progress: 0.7)).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.dark)
        }
    }
}
