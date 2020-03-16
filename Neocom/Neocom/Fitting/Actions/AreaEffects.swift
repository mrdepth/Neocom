//
//  AreaEffects.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.03.2020.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct AreaEffects: View {
	private class Effects: ObservableObject {
		var sections: [FetchedResultsController<SDEInvType>.Section]
		init(_ types: [SDEInvType]) {
			let prefixes = ["Black Hole Effect",
							"Cataclysmic Variable Effect",
							"Magnetar Effect",
							"Pulsar Effect",
							"Red Giant",
							"Wolf Rayet Effect",
							"Incursion",
							"Drifter Incursion",
							"Invasion"
			]

			sections = Dictionary(grouping: types) { type in
				prefixes.first{type.typeName?.hasPrefix($0) == true} ?? "\u{2063}Other"
			}
			.map {
				FetchedResultsController<SDEInvType>.Section(name: $0.key,
															 objects: $0.value.sorted{$0.typeName! < $1.typeName!})
//				Section(title: $0.key, types: $0.value.sorted{$0.typeName! < $1.typeName!})
			}.sorted{$0.name < $1.name}

		}
	}
	
	var completion: (SDEInvType) -> Void
	
	@State private var select: Int?
	@Environment(\.managedObjectContext) private var managedObjectContext
	@Environment(\.self) private var environment
	@State private var effects = Lazy<Effects>()
	@State private var selectedType: SDEInvType?
	
	private func getEffects() -> Effects {
		
		let types = try? managedObjectContext.from(SDEInvType.self)
			.filter(/\SDEInvType.group?.groupID == SDEGroupID.effectBeacon.rawValue)
			.fetch()
		return Effects(types ?? [])
	}
	
    var body: some View {
		let sections = effects.get(initial: getEffects()).sections
		
		return List {
			ForEach(sections, id: \.name) { section in
				Section(header: Text(section.name.uppercased())) {
					ForEach(section.objects, id: \.objectID) { type in
						HStack(spacing: 0) {
							Button(action: {self.completion(type)}) {
								HStack(spacing: 0) {
									TypeCell(type: type)
									Spacer()
								}.contentShape(Rectangle())
							}.buttonStyle(PlainButtonStyle())
							InfoButton {
								self.selectedType = type
							}
						}
					}
				}
			}
		}.listStyle(GroupedListStyle())
			.navigationBarTitle("Area Effects")
			.sheet(item: $selectedType) { type in
				NavigationView {
					TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
				}.modifier(ServicesViewModifier(environment: self.environment))
		}
    }
}

struct AreaEffects_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			AreaEffects() { _ in
				
			}
				.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
		}
    }
}
