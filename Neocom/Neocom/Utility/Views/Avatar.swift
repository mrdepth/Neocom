//
//  Avatar.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct Avatar: View {
    var image: Image?
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
            image?.resizable()
        }
        .clipShape(Circle())
        .shadow(radius: 2)
        .overlay(Circle().strokeBorder(Color(UIColor.tertiarySystemBackground), lineWidth: 2, antialiased: true))
    }
}

struct Avatar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Avatar(image: Image("character")).frame(width: 64, height: 64).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.light)
            Avatar(image: Image("character")).frame(width: 64, height: 64).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.dark)
            Avatar(image: nil).frame(width: 64, height: 64).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.light)
            Avatar(image: nil).frame(width: 64, height: 64).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.dark)
        }
    }
}
