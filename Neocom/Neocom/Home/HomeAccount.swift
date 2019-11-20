//
//  HomeAccount.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct HomeAccount: View {
    var body: some View {
		HStack {
			Image("character").resizable().frame(width: 64, height: 64).clipShape(Circle()).shadow(radius: 2).overlay(Circle().strokeBorder(Color(UIColor.tertiarySystemBackground), lineWidth: 2, antialiased: true))
			VStack(alignment: .leading, spacing: 0) {
				Text("Artem Valiant").font(.title)
				HStack {
					Image("corporation").resizable().frame(width: 32, height: 32)
				Text("NecroRise Squadron").font(.body).foregroundColor(.secondary)
				}
				HStack {
					Image("alliance").resizable().frame(width: 32, height: 32)
				Text("Alliance").foregroundColor(.secondary)
				}
			}//.padding()
			Spacer()
		}.padding()
    }
}

struct HomeAccount_Previews: PreviewProvider {
    static var previews: some View {
		VStack {
			HomeAccount()
			Spacer()
		}
    }
}
