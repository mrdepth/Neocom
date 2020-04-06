//
//  HomeLoginHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/29/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct HomeLoginHeader: View {
    var body: some View {
        VStack {
            Avatar(image: nil).frame(width: 64, height: 64).overlay(Image(systemName: "person").resizable().padding())
            Text("Tap to Login").font(.title2)
        }.padding().foregroundColor(.secondary)
    }
}

struct HomeLoginHeader_Previews: PreviewProvider {
    static var previews: some View {
        HomeLoginHeader()
    }
}
