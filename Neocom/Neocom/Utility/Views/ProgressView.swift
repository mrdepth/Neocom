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
            Rectangle()
                .fill(Color.accentColor.opacity(1.0))
                .frame(width: geometry.size.width * CGFloat(self.progress), alignment: .leading)
                .offset(x: -geometry.size.width * CGFloat(1.0 - self.progress) / 2, y: 0)
        }.overlay(Rectangle().strokeBorder(Color.accentColor, lineWidth: 1, antialiased: false))
            .background(Color.accentColor.opacity(0.5))

    }
}

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 10) {
            Text("70%").padding(.horizontal).background(ProgressView(progress: 0.7).accentColor(Color(.systemGray2))).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.light)
            Text("70%").padding(.horizontal).background(ProgressView(progress: 0.7).accentColor(Color(.systemGray2))).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.dark)
            Text("70%").padding(.horizontal).background(ProgressView(progress: 0.5).accentColor(.emDamage)).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.light).foregroundColor(.white)
            Text("70%").frame(maxWidth: .infinity).padding(.horizontal).background(ProgressView(progress: 0.5).accentColor(.emDamage)).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.dark)
        }
    }
}
