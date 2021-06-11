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
import Combine

struct SkillQueue: View {
    @ObservedObject private var pilot = Lazy<DataLoader<Pilot, AFError>, Account>()
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState

    private func loadPilot(account: Account, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> AnyPublisher<Pilot, AFError> {
        Pilot.load(sharedState.esi.characters.characterID(Int(account.characterID)), in: self.backgroundManagedObjectContext, cachePolicy: cachePolicy)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var body: some View {
        let loader = sharedState.account.map{account in self.pilot.get(account, initial: DataLoader(self.loadPilot(account: account)))}
        let pilot = loader?.result?.value

        let list = List {
            Section {
                NavigationLink(destination: Skills(editMode: false)) {
                    Text("Browse All Skills")
                }
                if pilot != nil && sharedState.account != nil {
                    OptimalAttributesRow(account: sharedState.account!, pilot: pilot!)
                }
            }
            if pilot != nil {
                SkillQueueSection(pilot: pilot!)
                sharedState.account.map { SkillPlanSectionWrapper(account: $0, pilot: pilot!) }
            }
        }
        .listStyle(GroupedListStyle())
        return Group {
            if loader != nil {
                list.onRefresh(isRefreshing: Binding(loader!, keyPath: \.isLoading)) {
                    guard let account = self.sharedState.account else {return}
                    loader?.update(self.loadPilot(account: account, cachePolicy: .reloadIgnoringLocalCacheData))
                }
            }
            else {
                list
            }
        }
        .navigationBarTitle(Text("Skill Queue"))
        .navigationBarItems(trailing: EditButton())
    }
}

struct OptimalAttributesRow: View {
    var pilot: Pilot
    
    @FetchRequest(sortDescriptors: [])
    private var skillPlans: FetchedResults<SkillPlan>

    init(account: Account, pilot: Pilot) {
        self.pilot = pilot
        let request = NSFetchRequest<SkillPlan>(entityName: "SkillPlan")
        request.predicate = (/\SkillPlan.account == account && /\SkillPlan.isActive == true).predicate()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SkillPlan.isActive, ascending: true),
                                   NSSortDescriptor(keyPath: \SkillPlan.name, ascending: true)]
        request.fetchLimit = 1
        _skillPlans = FetchRequest(fetchRequest: request)
    }

    var body: some View {
        (skillPlans.first).map {
            OptimalAttributesRowContent(pilot: pilot, skillPlan: $0)
        }
    }
}

struct OptimalAttributesRowContent: View {
    var pilot: Pilot
    @ObservedObject var skillPlan: SkillPlan
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        let trainingQueue = TrainingQueue(pilot: pilot, skillPlan: skillPlan)
        trainingQueue.add(pilot.skillQueue, managedObjectContext: managedObjectContext)
        let trainingTime = trainingQueue.trainingTime()
        let optimalAttributes = Pilot.Attributes(optimalFor: trainingQueue)
        let optimalTrainingTime = trainingQueue.trainingTime(with: optimalAttributes + pilot.augmentations)
        let dt = trainingTime - optimalTrainingTime

        return Group {
            if dt > 0 {
                NavigationLink(destination: OptimalAttributes(pilot: pilot, trainingQueue: trainingQueue)) {
                    VStack(alignment: .leading) {
                        Text("Optimal Remap")
                        Text("\(TimeIntervalFormatter.localizedString(from: dt, precision: .seconds)) better").modifier(SecondaryLabelModifier())
                    }
                }
            }
        }
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
        request.predicate = (/\SkillPlan.account == account && /\SkillPlan.isActive == true).predicate()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SkillPlan.isActive, ascending: true),
                                   NSSortDescriptor(keyPath: \SkillPlan.name, ascending: true)]
        request.fetchLimit = 1
        _skillPlans = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {

        return skillPlans.first.map{ skillPlan in
            SkillPlanSection(skillPlan: skillPlan, pilot: pilot)
        }
    }
}

#if DEBUG
struct SkillQueue_Previews: PreviewProvider {
    static var previews: some View {
        let account = Account.testingAccount
        let skillPlan = SkillPlan(context: Storage.testStorage.persistentContainer.viewContext)
        skillPlan.account = account
        skillPlan.name = "SkillPlan 1"
        skillPlan.isActive = true

        return NavigationView {
            SkillQueue()
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
