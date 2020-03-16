//
//  FittingEditorActions.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.03.2020.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorActions: View {
	@EnvironmentObject private var ship: DGMShip
	@EnvironmentObject private var gang: DGMGang
	@Environment(\.managedObjectContext) private var managedObjectContext
	@State private var isAreaEffectsPresented = false
	
	private var areaEffects: some View {
		AreaEffects { type in
			self.gang.area = try? DGMArea(typeID: DGMTypeID(type.typeID))
			self.isAreaEffectsPresented = false
		}
	}
	
    var body: some View {
		let type = ship.type(from: managedObjectContext)
		let area = gang.area?.type(from: managedObjectContext)
		return List {
			Section(header: Text("SHIP NAME")) {
				TextField(type?.typeName ?? "Ship Name", text: $ship.name)
			}
			type.map {type in
				Section(header: Text("SHIP")) {
					NavigationLink(destination: TypeInfo(type: type)) {
						TypeCell(type: type)
					}
				}
			}
			Section(header: Text("AREA EFFECTS")) {
				NavigationLink(destination: areaEffects, isActive: $isAreaEffectsPresented) {
					if area != nil {
						TypeCell(type: area!)
					}
					else {
						Text("None")
					}
				}
			}
		}.listStyle(GroupedListStyle())
    }
}

struct FittingEditorActions_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditorActions()
        }
        .environmentObject(gang.pilots.first!.ship!)
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
