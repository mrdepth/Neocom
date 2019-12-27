//
//  TypeMasterySkills.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/6/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData

struct TypeMasterySkills: View {
    var skills: [SDECertSkill]
    var pilot: Pilot?
    
    var body: some View {
        List(skills, id: \.self) { skill in
            TypeInfoSkillCell(skillType: skill.type!, level: Int(skill.skillLevel), pilot: self.pilot)
        }
    }
}

struct TypeMasterySkills_Previews: PreviewProvider {
    static var previews: some View {
        let type = try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!
        let level = ((type.certificates?.anyObject() as? SDECertCertificate)?.masteries?.firstObject as? SDECertMastery)?.level
        let data = MasteryData(for: type, with: level!, pilot: nil)

        return NavigationView {
            TypeMasterySkills(skills: data.sections.first?.skills ?? [], pilot: nil)
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
