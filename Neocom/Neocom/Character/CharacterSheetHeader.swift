//
//  CharacterSheetHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct CharacterSheetHeader: View {
    var characterName: String?
    var characterImage: UIImage?
    var corporationName: String?
    var corporationImage: UIImage?
    var allianceName: String?
    var allianceImage: UIImage?
    
    private var title: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(characterName ?? "").font(.title)
            if corporationName != nil {
                HStack {
                    if corporationImage != nil {
                        Icon(Image(uiImage: corporationImage!))
                    }
                    Text(corporationName!)
                }
            }
            if allianceName != nil {
                HStack {
                    if allianceImage != nil {
                        Icon(Image(uiImage: allianceImage!))
                    }
                    Text(allianceName!)
                }
            }
        }
        .padding(8)
        .background(Color(.systemFill).cornerRadius(8))
        .padding()
        .colorScheme(.dark)
    }
    
    var body: some View {
        Image(uiImage: characterImage ?? UIImage()).resizable().scaledToFit()
            .overlay(title, alignment: .bottomLeading)
    }
}

struct CharacterSheetHeader_Previews: PreviewProvider {
    static var previews: some View {
        CharacterSheetHeader(characterName: "Artem Valiant",
                             characterImage: UIImage(named: "character"),
                             corporationName: "Necrorise Squadron",
                             corporationImage: UIImage(named: "corporation"),
                             allianceName: "Red Alert",
                             allianceImage: UIImage(named: "alliance"))
    }
}
