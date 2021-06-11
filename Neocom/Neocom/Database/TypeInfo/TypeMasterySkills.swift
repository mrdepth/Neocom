//
//  TypeMasterySkills.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TypeMasterySkills: View {
    var data: MasteryData.Section
    var pilot: Pilot?

    
    var body: some View {
        List {
            Section(footer: data.subtitle.map{Text("Training time: \($0)").frame(maxWidth: .infinity)}) {
                ForEach(data.skills, id: \.objectID) { skill in
                    TypeInfoSkillCell(skillType: skill.type!, level: Int(skill.skillLevel), pilot: self.pilot)
                }
            }
        }.listStyle(GroupedListStyle())
            .navigationBarTitle(data.title)
            .navigationBarItems(trailing: AddToSkillPlanButton(trainingQueue: data.trainingQueue))
    }
}

#if DEBUG
struct TypeMasterySkills_Previews: PreviewProvider {
    static var previews: some View {
        let type = SDEInvType.dominix
        let level = ((type.certificates?.anyObject() as? SDECertCertificate)?.masteries?.firstObject as? SDECertMastery)?.level
        let data = MasteryData(for: type, with: level!, pilot: nil)
        
        return NavigationView {
            TypeMasterySkills(data: data.sections[0])
        }
    }
}
#endif
