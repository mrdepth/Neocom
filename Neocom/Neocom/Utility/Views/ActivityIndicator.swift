//
//  ActivityView.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct ActivityIndicator: View {
    var body: some View {
        ZStack {
            Color.clear
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
            ActivityIndicatorView(style: .large)
                .frame(width: 128, height: 128)
                .background(BlurView())
                .cornerRadius(16)
        }
    }
}

struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicator()
    }
}
