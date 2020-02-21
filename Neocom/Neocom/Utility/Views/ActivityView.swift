//
//  ActivityView.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct ActivityView: View {
    var body: some View {
        ZStack {
            Color.clear
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
            ActivityIndicator(style: .large)
                .frame(width: 128, height: 128)
                .background(BlurView())
                .cornerRadius(16)
        }.onTapGesture {
            print("tap")
        }
    }
}

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
