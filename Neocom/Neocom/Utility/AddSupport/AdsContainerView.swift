//
//  AdsContainerView.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct AdsContainerView<Content: View>: View {
    private var content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
            Color.green.frame(height: 50)
        }
    }
}

struct AdsContainerView_Previews: PreviewProvider {
    static var previews: some View {
        AdsContainerView {
            NavigationView {
                List {
                    Text(verbatim: "Hello, World")
                }.listStyle(GroupedListStyle())
            }.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
