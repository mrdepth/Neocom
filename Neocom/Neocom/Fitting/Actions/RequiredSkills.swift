//
//  RequiredSkills.swift
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
import Combine

struct RequiredSkills: View {
    @EnvironmentObject private var ship: DGMShip
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account
    @ObservedObject private var skills = Lazy<FetchedResultsController<SDEInvType>>()
    @ObservedObject private var pilot = Lazy<DataLoader<Pilot, AFError>>()
    @ObservedObject private var levels = Lazy<DataLoader<[DGMTypeID: Int], Never>>()

    private func loadPilot(account: Account) -> DataLoader<Pilot, AFError> {
        DataLoader(Pilot.load(esi.characters.characterID(Int(account.characterID)), in: self.backgroundManagedObjectContext).receive(on: RunLoop.main))
    }
    
    private func getSkills() -> FetchedResultsController<SDEInvType> {
        let typeIDs = Set([[ship.typeID], ship.modules.map{$0.typeID}, ship.drones.map{$0.typeID}].joined())
        let types = try? managedObjectContext
            .from(SDEInvType.self)
            .filter((/\SDEInvType.typeID).in(typeIDs))
            .fetch()
        let trainingQueue = TrainingQueue(pilot: .empty)
        types?.forEach{trainingQueue.addRequiredSkills(for: $0)}
        
        let skillIDs = Set(trainingQueue.queue.map{$0.skill.typeID})
        
        let controller = managedObjectContext
            .from(SDEInvType.self)
            .filter(/\SDEInvType.published == true && /\SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue && (/\SDEInvType.typeID).in(skillIDs))
            .sort(by: \SDEInvType.group?.groupName, ascending: true)
            .sort(by: \SDEInvType.typeName, ascending: true)
            .fetchedResultsController(sectionName: /\SDEInvType.group?.groupName, cacheName: nil)
        return FetchedResultsController(controller)
    }
    
    private func getLevels(skills: [SDEInvType]) -> DataLoader<[DGMTypeID: Int], Never> {
        let trainingQueue = TrainingQueue(pilot: .empty)
        skills.forEach {trainingQueue.addRequiredSkills(for: $0)}
        let levels = Dictionary(trainingQueue.queue.map{($0.skill.typeID, $0.targetLevel)}) {a, b in max(a, b)}
        return DataLoader(Just(levels))
    }
    
    var body: some View {
        let skills = self.skills.get(initial: self.getSkills())
        let pilot = account.map{account in self.pilot.get(initial: self.loadPilot(account: account))}?.result?.value
        let levels = self.levels.get(initial: getLevels(skills: skills.fetchedObjects)).result?.value ?? [:]

        let trainingQueue = TrainingQueue(pilot: pilot ?? .empty)
        for type in skills.fetchedObjects {
            trainingQueue.add(type, level: levels[DGMTypeID(type.typeID)] ?? 1)
        }

        return List {
            ForEach(skills.sections, id: \.name) { section in
                RequiredSkillsSection(skills: section, pilot: pilot, levels: levels)
            }
        }.listStyle(GroupedListStyle())
        .navigationBarTitle("Required Skills")
            .navigationBarItems(trailing: pilot != nil && trainingQueue.trainingTime() > 0 ? AddToSkillPlanButton(trainingQueue: trainingQueue) : nil)
    }
}

struct RequiredSkillsSection: View {
    var skills: FetchedResultsController<SDEInvType>.Section
    var pilot: Pilot?
    var levels: [DGMTypeID: Int]
    
    var body: some View {
        let trainingQueue = TrainingQueue(pilot: pilot ?? .empty)
        for type in skills.objects {
            trainingQueue.add(type, level: levels[DGMTypeID(type.typeID)] ?? 1)
        }
        let trainingTime = trainingQueue.trainingTime()
        let header = trainingTime > 0 ? Text("\(skills.name.uppercased()) (\(TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds).uppercased()))") : Text(skills.name.uppercased())
        
        return Section(header: header) {
            ForEach(skills.objects, id: \.objectID) { type in
                SkillCell(type: type, pilot: self.pilot, targetLevel: self.levels[DGMTypeID(type.typeID)] ?? 0)
            }
        }
    }
}

struct RequiredSkills_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        let gang = DGMGang.testGang()
        return NavigationView {
            RequiredSkills()
        }
        .environmentObject(gang.pilots.first!.ship!)
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environment(\.account, account)
        .environment(\.esi, esi)
    }
}
