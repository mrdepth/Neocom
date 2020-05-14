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
	@ObservedObject var ship: DGMShip
    var completion: () -> Void
    
	@EnvironmentObject private var gang: DGMGang
	@Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
	@State private var isAreaEffectsPresented = false
    @State private var isCharactersPresented = false
    @State private var isDamagePatternsPresented = false
    @State private var isActivityPresented = false
    @EnvironmentObject private var sharedState: SharedState
    @EnvironmentObject private var project: FittingProject
	
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
    
    private var saveButton: some View {
        Group {
            if project.loadouts[ship] == nil {
                Button(action: {
                    self.project.save()
                    self.completion()
                }) {
                    Text("Save").padding(.horizontal, 8).contentShape(Rectangle())
                }
            }
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
                NavigationLink(destination: AffectingSkills(ship: ship)) {
                    Text("Affecting Skill")
                }
                NavigationLink(destination: RequiredSkills(ship: ship)) {
                    Text("Required Skill")
                }
            }
            
            Section {
                Button("Share") {
                    self.isActivityPresented = true
                }.frame(maxWidth: .infinity)
                .activityView(isPresented: $isActivityPresented, activityItems: [LoadoutActivityItem(ships: [ship.loadout], managedObjectContext: managedObjectContext)], applicationActivities: [InGameActivity(environment: environment, sharedState: sharedState)])

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
        .navigationBarTitle("Actions")
        .navigationBarItems(leading: BarButtonItems.close(completion), trailing: saveButton)

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

#if DEBUG
struct FittingEditorShipActions_Previews: PreviewProvider {
    static var previews: some View {  
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditorShipActions(ship: gang.pilots.first!.ship!) {}
        }
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
        .environmentObject(FittingProject(gang: gang, managedObjectContext: AppDelegate.sharedDelegate.persistentContainer.viewContext))

    }
}
#endif
