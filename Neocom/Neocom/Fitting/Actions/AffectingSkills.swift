//
//  AffectingSkills.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/18/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible
import Alamofire
import EVEAPI

struct AffectingSkills: View {
    @ObservedObject var ship: DGMShip
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var skills = Lazy<FetchedResultsController<SDEInvType>, Never>()
    @ObservedObject private var pilot = Lazy<DataLoader<Pilot, AFError>, Never>()
    
    private func loadPilot(account: Account) -> DataLoader<Pilot, AFError> {
        DataLoader(Pilot.load(sharedState.esi.characters.characterID(Int(account.characterID)), in: self.backgroundManagedObjectContext).receive(on: RunLoop.main))
    }

    private func getSkills() -> FetchedResultsController<SDEInvType> {
        let typeIDs = Set([ship.affectors.map{$0.typeID}, ship.modules.flatMap{$0.affectors.map{$0.typeID}}, ship.drones.flatMap{$0.affectors.map{$0.typeID}}].joined())
        
        let controller = managedObjectContext
            .from(SDEInvType.self)
            .filter(/\SDEInvType.published == true && /\SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue && (/\SDEInvType.typeID).in(typeIDs))
            .sort(by: \SDEInvType.group?.groupName, ascending: true)
            .sort(by: \SDEInvType.typeName, ascending: true)
            .fetchedResultsController(sectionName: /\SDEInvType.group?.groupName, cacheName: nil)
        return FetchedResultsController(controller)
    }

    var body: some View {
        let skills = self.skills.get(initial: self.getSkills())
        let pilot = sharedState.account.map{account in self.pilot.get(initial: self.loadPilot(account: account))}?.result?.value

        return List {
            ForEach(skills.sections, id: \.name) { section in
                AffectingSkillsSection(skills: section, pilot: pilot)
            }
        }.listStyle(GroupedListStyle())
        .navigationBarTitle("Affecting Skills")
    }
}

struct AffectingSkillsSection: View {
    var skills: FetchedResultsController<SDEInvType>.Section
    var pilot: Pilot?
    
    var body: some View {
        Section(header: Text(skills.name.uppercased())) {
            ForEach(skills.objects, id: \.objectID) { type in
                SkillCell(type: type, pilot: self.pilot)
            }
        }
    }
}

#if DEBUG
struct AffectingSkills_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        let gang = DGMGang.testGang()
        return NavigationView {
            AffectingSkills(ship: gang.pilots.first!.ship!)
        }
        .environmentObject(gang)
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
#endif
