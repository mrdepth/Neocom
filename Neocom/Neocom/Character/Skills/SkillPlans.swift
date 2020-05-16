//
//  SkillPlans.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import Alamofire

struct SkillPlans: View {
    var completion: (SkillPlan) -> Void
    
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
    @ObservedObject private var pilot = Lazy<DataLoader<Pilot, AFError>, Account>()
    
    private func getPilot(_ characterID: Int64) -> DataLoader<Pilot, AFError> {
        DataLoader(Pilot.load(sharedState.esi.characters.characterID(Int(characterID)), in: backgroundManagedObjectContext).receive(on: RunLoop.main))
    }

    var body: some View {
        let pilot = sharedState.account.map{self.pilot.get($0, initial: getPilot($0.characterID))}?.result?.value

        return sharedState.account.map {
            SkillPlansContent(account: $0, pilot: pilot ?? .empty, completion: completion)
        }
    }
}

struct SkillPlansContent: View {
    @FetchRequest(sortDescriptors: [])
    var skillPlans: FetchedResults<SkillPlan>
    var account: Account
    var pilot: Pilot
    var completion: (SkillPlan) -> Void

    @State private var isTextAlertPresented = false
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var selectedSkillPlan: SkillPlan?
    
    @State private var renamedSkillPlan: SkillPlan?

    init(account: Account, pilot: Pilot, completion: @escaping (SkillPlan) -> Void) {
        self.account = account
        self.pilot = pilot
        self.completion = completion
        _skillPlans = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SkillPlan.name, ascending: true)],
                                   predicate: (/\SkillPlan.account == account).predicate(),
                                   animation: nil)
    }
    
    private func subtitle(for skillPlan: SkillPlan) -> some View {
        let trainingTime = TrainingQueue(pilot: pilot, skillPlan: skillPlan).trainingTime()
        if trainingTime > 0 {
            return Text("\(skillPlan.skills?.count ?? 0) skills (\(TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds)))")
        }
        else {
            return Text("Skill Plan is empty")
        }
    }
    

    private func onAddSkillPlan() {
        withAnimation {
            isTextAlertPresented = true
        }
    }
    
    
    private func rename(_ skillPlan: SkillPlan) {
        withAnimation {
            self.renamedSkillPlan = skillPlan
        }
    }

    private func makeActive(_ skillPlan: SkillPlan) {
        skillPlans.forEach{$0.isActive = false}
        skillPlan.isActive = true
        completion(skillPlan)
    }
    
    private func clear(_ skillPlan: SkillPlan) {
        (skillPlan.skills?.allObjects as? [SkillPlanSkill])?.forEach { skill in
            skillPlan.managedObjectContext?.delete(skill)
        }
    }

    private func delete(_ skillPlan: SkillPlan) {
        skillPlan.managedObjectContext?.delete(skillPlan)
    }

    private func actionSheet(for skillPlan: SkillPlan) -> ActionSheet {
        var buttons: [ActionSheet.Button] = []
        
        if (skillPlan.skills?.count ?? 0) > 0 {
            buttons.append(ActionSheet.Button.default(Text("Clear"), action: { self.clear(skillPlan) }))
        }
        buttons.append(ActionSheet.Button.default(Text("Make Active"), action: { self.makeActive(skillPlan) }))
        buttons.append(ActionSheet.Button.default(Text("Rename"), action: { self.rename(skillPlan) }))
        buttons.append(ActionSheet.Button.destructive(Text("Delete"), action: { self.delete(skillPlan) }))
        buttons.append(ActionSheet.Button.cancel())

        return ActionSheet(title: skillPlan.name.map{Text($0)} ?? Text("Unnamed"), message: nil, buttons: buttons)
    }
    
    var body: some View {
        ZStack {
            List {
                ForEach(skillPlans, id: \.objectID) { skillPlan in
                    Button(action: {self.makeActive(skillPlan)}) {
                        HStack {
                            if skillPlan.isActive {
                                Image(systemName: "checkmark")
                            }
                            VStack(alignment: .leading) {
                                skillPlan.name.map{Text($0)} ?? Text("Unnamed").italic()
                                self.subtitle(for: skillPlan).modifier(SecondaryLabelModifier())
                            }.accentColor(.primary)
                            Spacer()
                            Button(action: {
                                self.selectedSkillPlan = skillPlan
                            }) {
                                Image(systemName: "ellipsis")
                            }
                        }
                    }
                }.onDelete { (indices) in
                    indices.map{self.skillPlans[$0]}.forEach { $0.managedObjectContext?.delete($0) }
                }
            }.listStyle(GroupedListStyle())
            if isTextAlertPresented {
                TextFieldAlert(title: "New Skill Plan", placeholder: "Name", text: "") { (result) in
                    if case let .success(name) = result {
                        let skillPlan = SkillPlan(context: self.managedObjectContext)
                        skillPlan.name = name
                        skillPlan.account = self.account
                    }
                    withAnimation {
                        self.isTextAlertPresented = false
                    }
                }
            }
            if renamedSkillPlan != nil {
                TextFieldAlert(title: "Rename", placeholder: "Name", text: renamedSkillPlan?.name ?? "") { (result) in
                    if case let .success(name) = result {
                        self.renamedSkillPlan?.name = name
                    }
                    withAnimation {
                        self.renamedSkillPlan = nil
                    }
                }
            }
        }
        .navigationBarTitle("Skill Plans")
        .navigationBarItems(leading: BarButtonItems.close { },
                            trailing: Button(action: onAddSkillPlan) { Image(systemName: "plus") })
        .actionSheet(item: $selectedSkillPlan, content: actionSheet)
    }
}

#if DEBUG
struct SkillPlans_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        _ = try? Storage.sharedStorage.persistentContainer.viewContext.from(SkillPlan.self).delete()
        
        let skillPlan1 = SkillPlan(context: Storage.sharedStorage.persistentContainer.viewContext)
        let skillPlan2 = SkillPlan(context: Storage.sharedStorage.persistentContainer.viewContext)
        skillPlan1.name = "SkillPlan 1"
        skillPlan1.account = account
        skillPlan2.account = account
        
        return NavigationView {
            SkillPlans() { _ in }
                .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
                .environmentObject(SharedState.testState())
        }
    }
}
#endif
