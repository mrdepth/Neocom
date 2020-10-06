//
//  FleetPilotCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/20/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible

struct FleetPilotCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @Binding var ship: DGMShip
    @ObservedObject var pilot: DGMCharacter
    
    var body: some View {
        let type = pilot.ship?.type(from: managedObjectContext)
        let url = pilot.url
        
        let account = url.flatMap{DGMCharacter.account(from: $0)}.flatMap{try? managedObjectContext.fetch($0).first}
        let level = url.flatMap{DGMCharacter.level(from: $0)} ?? 0
        let name = pilot.ship?.name

        return Group {
            HStack {
                if type != nil {
                    Icon(type!.image).cornerRadius(4)
                }
                VStack(alignment: .leading) {
                    type?.typeName.map {Text($0)} ?? Text("Unknown")
                    if name?.isEmpty == false {
                        Text(name!).modifier(SecondaryLabelModifier())
                    }
                }

                Spacer()
                HStack {
                    if account != nil {
                        Text(account?.characterName ?? "")
                        Avatar(characterID: account!.characterID, size: .size128).frame(width: 24, height: 24)
                    }
                    else {
                        Text("All Skills ") + Text(level == 0 ? "0" : String(roman: level)).fontWeight(.semibold)
                        LevelAvatar(level: level).frame(width: 24, height: 24)
                    }
                }.modifier(SecondaryLabelModifier())
            }.opacity(ship == pilot.ship ? 1 : 0.5)
        }
    }
}

struct FleetPilotCell_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        
        return List {
            FleetPilotCell(ship: .constant(gang.pilots[0].ship!), pilot: gang.pilots[0])
            }.listStyle(GroupedListStyle())
            .environmentObject(gang)
        .modifier(ServicesViewModifier.testModifier())

    }
}
