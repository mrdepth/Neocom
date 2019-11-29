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
        HStack {
            Image(systemName: "person")
                .resizable()
                .foregroundColor(.secondary)
                .scaledToFit()
                .padding()
                .frame(width: 64, height: 64)
                .background(Color(.systemBackground))
                .clipShape(Circle()).shadow(radius: 2).overlay(Circle().strokeBorder(Color(UIColor.tertiarySystemBackground), lineWidth: 2, antialiased: true))
            Text("Login").font(.title)
            Spacer()
        }.padding()
    }
}

struct HomeLoginHeader_Previews: PreviewProvider {
    static var previews: some View {
        HomeLoginHeader()
    }
}
