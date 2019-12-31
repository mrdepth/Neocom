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

        
        return Section(header: Text(title.uppercased())) {
            ForEach(SkillsList(requiredSkillsFor: type).skills, id: \.type.objectID) {
                TypeInfoSkillCell(skillType: $0.type, level: Int($0.level), pilot: self.pilot)
            }
        }
    }
}

struct TypeInfoRequiredSkillsSection_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                TypeInfoRequiredSkillsSection(type: .dominix, pilot: nil)
            }.listStyle(GroupedListStyle())
        }
    }
}
