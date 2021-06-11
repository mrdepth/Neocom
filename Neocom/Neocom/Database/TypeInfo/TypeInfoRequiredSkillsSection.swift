//
//  TypeInfoRequiredSkillsSection.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/31/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TypeInfoRequiredSkillsSection: View {
    var type: SDEInvType
    var pilot: Pilot?
    
    var body: some View {
        let trainingQueue = TrainingQueue(pilot: pilot ?? .empty)
        trainingQueue.addRequiredSkills(for: type)
        let time = trainingQueue.trainingTime()
        let title = time > 0 ? NSLocalizedString("Required Skills", comment: "") + ": " + TimeIntervalFormatter.localizedString(from: time, precision: .seconds) : NSLocalizedString("Required Skills", comment: "")

        let header = HStack {
            Text(title.uppercased())
            Spacer()
            AddToSkillPlanButton(trainingQueue: trainingQueue)
        }

        
        return Section(header: header) {
            ForEach(SkillsList(requiredSkillsFor: type).skills, id: \.type.objectID) {
                TypeInfoSkillCell(skillType: $0.type, level: Int($0.level), pilot: self.pilot)
            }
        }
    }
}

#if DEBUG
struct TypeInfoRequiredSkillsSection_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                TypeInfoRequiredSkillsSection(type: .dominix, pilot: nil)
            }.listStyle(GroupedListStyle())
        }
    }
}
#endif
