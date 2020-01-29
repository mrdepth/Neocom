//
//  SkillPlanSection.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import CoreData
import EVEAPI

struct SkillPlanSection: View {
    var skillPlan: SkillPlan
    var pilot: Pilot
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest(sortDescriptors: [])
    var skills: FetchedResults<SkillPlanSkill>

    init(skillPlan: SkillPlan, pilot: Pilot) {
        self.skillPlan = skillPlan
        self.pilot = pilot
        _skills = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SkillPlanSkill.position, ascending: true)],
                               predicate: (\SkillPlanSkill.skillPlan == skillPlan).predicate(),
                               animation: nil)
    }
    
    var header: some View {
        HStack {
            skillPlan.name.map{Text($0)} ?? Text("UNNAMED")
            Spacer()
            Button(action: {
                
            }) {
                Image(systemName: "ellipsis")
            }
        }
    }
    
    var body: some View {
        Section(header: header) {
            ForEach(skills, id: \.objectID) { skill in
                Group {
                    if (self.pilot.trainedSkills[Int(skill.typeID)]?.trainedSkillLevel ?? 0) < Int(skill.level) {
                        (try? self.managedObjectContext.from(SDEInvType.self).filter(\SDEInvType.typeID == skill.typeID).first()).map { type in
                            SkillCell(type: type, pilot: self.pilot, skillPlanSkill: skill)
                        }
                    }
                }
//                Text("Hello, World!")
            }.onDelete { (indices) in
                for i in indices {
                    let skill = self.skills[i]
                    skill.managedObjectContext?.delete(skill)
                }
            }
        }
    }
}

struct SkillPlanSection_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        let type = try! AppDelegate.sharedDelegate.persistentContainer.viewContext
            .from(SDEInvType.self)
            .filter(\SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue)
            .first()!

        let skillPlan = SkillPlan(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        let skills = (0..<4).map { i -> SkillPlanSkill in
            let skill = SkillPlanSkill(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
            skill.typeID = type.typeID
            skill.level = Int16(i)
            skill.skillPlan = skillPlan
            skill.position = Int32(i)
            return skill
        }
        return List {
            SkillPlanSection(skillPlan: skillPlan, pilot: .empty)
                .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
                .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
                .environment(\.account, account)
                .environment(\.esi, esi)
            }.listStyle(GroupedListStyle())


    }
}
