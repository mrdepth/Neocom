//
//  HomeAccountHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct HomeAccountHeader: View {
    var characterName: String
    var corporationName: String?
    var allianceName: String?
    var characterImage: Image?
    var corporationImage: Image?
    var allianceImage: Image?
    
    var body: some View {
		HStack {
			characterImage?.resizable().frame(width: 64, height: 64).clipShape(Circle()).shadow(radius: 2).overlay(Circle().strokeBorder(Color(UIColor.tertiarySystemBackground), lineWidth: 2, antialiased: true))
			VStack(alignment: .leading, spacing: 0) {
				Text(characterName).font(.title)
				HStack {
                    corporationImage?.resizable().frame(width: 24, height: 24)
                    corporationName.map{Text($0)}.font(.body).foregroundColor(.secondary)
				}
				HStack {
					allianceImage?.resizable().frame(width: 24, height: 24)
                    allianceName.map{Text($0)}.foregroundColor(.secondary)
				}
			}//.padding()
			Spacer()
		}.padding()
    }
}

struct HomeAccountHeader_Previews: PreviewProvider {
    static var previews: some View {
		VStack {
            HomeAccountHeader(characterName: "Artem Valiant", corporationName: "Necrorise Squadron", allianceName: "Red Alert", characterImage: Image("character"), corporationImage: Image("corporation"), allianceImage: Image("alliance"))
			Spacer()
        }
    }
}
