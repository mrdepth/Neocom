//
//  SkillPlans.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct SkillPlans: View {
    @Environment(\.account) var account
    
    var body: some View {
        account.map {
            SkillPlansContent(account: $0)
        }
    }
}

struct SkillPlansContent: View {
    @FetchRequest(sortDescriptors: [])
    var skillPlans: FetchedResults<SkillPlan>
    
    init(account: Account) {
        _skillPlans = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SkillPlan.name, ascending: true)],
                                   predicate: (\SkillPlan.account == account).predicate(),
                                   animation: nil)
    }
    
    var body: some View {
        List {
            ForEach(skillPlans, id: \.objectID) { skillPlan in
                VStack(alignment: .leading) {
                    skillPlan.name.map{Text($0)} ?? Text("Unnamed").italic()
                    Text("\(skillPlan.skills?.count ?? 0) skills").modifier(SecondaryLabelModifier())
                }
            }.onDelete { (indices) in
            }
        }.listStyle(GroupedListStyle())
        .navigationBarTitle("Skill Plans")
        .navigationBarItems(trailing: EditButton())
    }
}

struct SkillPlans_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        _ = try? AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SkillPlan.self).delete()
        
        let skillPlan1 = SkillPlan(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        let skillPlan2 = SkillPlan(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        skillPlan1.name = "SkillPlan 1"
        skillPlan1.account = account
        skillPlan2.account = account
        
        return NavigationView {
            SkillPlans()
                .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
                .environment(\.account, account)
        }
    }
}
