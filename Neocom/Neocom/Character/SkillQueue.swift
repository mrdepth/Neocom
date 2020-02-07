//
//  SkillQueue.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/28/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Alamofire
import EVEAPI
import Expressible
import CoreData

struct SkillQueue: View {
    @ObservedObject private var pilot = Lazy<DataLoader<Pilot, AFError>>()
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account

    private func loadPilot(account: Account) -> DataLoader<Pilot, AFError> {
        DataLoader(Pilot.load(esi.characters.characterID(Int(account.characterID)), in: self.backgroundManagedObjectContext).receive(on: RunLoop.main))
    }

    var body: some View {
        let pilot = account.map{account in self.pilot.get(initial: self.loadPilot(account: account))}?.result?.value
        

        return List {
            NavigationLink(destination: Skills()) {
                Text("Browse All Skills")
            }
            if pilot != nil {
                account.map { SkillPlanSectionWrapper(account: $0, pilot: pilot!) }
            }
        }.listStyle(GroupedListStyle())
            .navigationBarTitle("Skill Queue")
        .navigationBarItems(trailing: EditButton())
    }
}

struct SkillPlanSectionWrapper: View {
    var pilot: Pilot
    @FetchRequest(sortDescriptors: [])
    var skillPlans: FetchedResults<SkillPlan>
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    init(account: Account, pilot: Pilot) {
        self.pilot = pilot
        let request = NSFetchRequest<SkillPlan>(entityName: "SkillPlan")
        request.predicate = (\SkillPlan.account == account && \SkillPlan.isActive == true).predicate()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SkillPlan.isActive, ascending: true),
                                   NSSortDescriptor(keyPath: \SkillPlan.name, ascending: true)]
        request.fetchLimit = 1
        _skillPlans = FetchRequest(fetchRequest: request)
    }
    
    private func attributes(_ skillPlan: SkillPlan) -> some View {
        let trainingQueue = TrainingQueue(pilot: pilot)
        trainingQueue.add(pilot.skillQueue, managedObjectContext: managedObjectContext)
        trainingQueue.add(skillPlan)
        let trainingTime = trainingQueue.trainingTime()
        let optimalAttributes = Pilot.Attributes(optimalFor: trainingQueue)
        let optimalTrainingTime = trainingQueue.trainingTime(with: optimalAttributes + pilot.augmentations)
        let dt = trainingTime - optimalTrainingTime
        return NavigationLink(destination: OptimalAttributes(pilot: pilot, trainingQueue: trainingQueue)) {
            VStack(alignment: .leading) {
                Text("Optimal Remap")
                if dt > 0 {
                    Text("\(TimeIntervalFormatter.localizedString(from: dt, precision: .seconds)) better").modifier(SecondaryLabelModifier())
                }
            }
        }
    }
    
    var body: some View {

        return skillPlans.first.map{ skillPlan in
            Group {
                attributes(skillPlan)
                SkillQueueSection(pilot: pilot)
                SkillPlanSection(skillPlan: skillPlan, pilot: pilot)
            }
        }
    }
}


struct SkillQueue_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        let skillPlan = SkillPlan(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        skillPlan.account = account
        skillPlan.name = "SkillPlan 1"
        skillPlan.isActive = true

        return NavigationView {
            SkillQueue()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environment(\.account, account)
        .environment(\.esi, esi)
    }
}
