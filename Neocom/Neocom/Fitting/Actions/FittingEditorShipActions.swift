//
//  FittingEditorShipActions.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.03.2020.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import CoreData
import EVEAPI

struct FittingEditorShipActions: View {
	@EnvironmentObject private var ship: DGMShip
	@EnvironmentObject private var gang: DGMGang
	@Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
	@State private var isAreaEffectsPresented = false
    @State private var isCharactersPresented = false
    @State private var isDamagePatternsPresented = false
    @State private var isActivityPresented = false
    @EnvironmentObject private var sharedState: SharedState
	
	private var areaEffects: some View {
		AreaEffects { type in
			self.gang.area = try? DGMArea(typeID: DGMTypeID(type.typeID))
			self.isAreaEffectsPresented = false
		}
	}

    private var characters: some View {
        FittingCharacters { url, skills in
            self.isCharactersPresented = false
            guard let pilot = self.ship.parent as? DGMCharacter else {return}
            pilot.url = url
            pilot.setSkillLevels(skills)
        }
    }

    var body: some View {
		let type = ship.type(from: managedObjectContext)
		let area = gang.area?.type(from: managedObjectContext)
		return List {
			type.map {type in
				Section(header: Text("SHIP")) {
                    TextField("Ship Name", text: $ship.name)
					NavigationLink(destination: TypeInfo(type: type)) {
						TypeCell(type: type)
					}
				}
			}
            Section(header: Text("CHARACTER")) {
                NavigationLink(destination: characters, isActive: $isCharactersPresented) {
                    FittingEditorActionsCharacterCell(url: (ship.parent as? DGMCharacter)?.url)
                }
            }
            Section(header: Text("DAMAGE PATTERN")) {
                Button(action: {self.isDamagePatternsPresented = true}) {
                    DamageVectorView(damage: ship.damagePattern).frame(height: 30)
                    .contentShape(Rectangle())
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
            Section {
                NavigationLink(destination: AffectingSkills()) {
                    Text("Affecting Skill")
                }
                NavigationLink(destination: RequiredSkills()) {
                    Text("Required Skill")
                }
            }
            
            Section {
                Button("Share") {
                    self.isActivityPresented = true
                }.frame(maxWidth: .infinity)
            }
		}
        .listStyle(GroupedListStyle())
        .sheet(isPresented: $isDamagePatternsPresented) {
            NavigationView {
                DamagePatterns { vector in
                    self.ship.damagePattern = vector
                    self.isDamagePatternsPresented = false
                }.navigationBarItems(leading: BarButtonItems.close {
                    self.isDamagePatternsPresented = false
                })
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .activityView(isPresented: $isActivityPresented, activityItems: [LoadoutActivityItem(ships: [ship.loadout], managedObjectContext: managedObjectContext)], applicationActivities: [InGameActivity(environment: environment, sharedState: sharedState)])
        .navigationBarTitle("Actions")
    }
}

private struct FittingEditorActionsCharacterCell: View {
    var url: URL?
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        let account = url.flatMap{DGMCharacter.account(from: $0)}.flatMap{try? managedObjectContext.fetch($0).first}
        let level = url.flatMap{DGMCharacter.level(from: $0)}
        
        return Group {
            if account != nil {
                FittingCharacterAccountCell(account: account!)
            }
            else if level != nil {
                FittingCharacterLevelCell(level: level!)
            }
            else {
                FittingCharacterLevelCell(level: 0)
            }
        }
    }
}

struct FittingEditorShipActions_Previews: PreviewProvider {
    static var previews: some View {  
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditorShipActions()
        }
        .environmentObject(gang.pilots.first!.ship!)
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())

    }
}
