//
//  SkillQueueSection.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct SkillQueueSection: View {
    var pilot: Pilot

    @Environment(\.managedObjectContext) private var managedObjectContext

    var body: some View {
        let date = Date()
        let skillQueue = pilot.skillQueue.filter{($0.queuedSkill.finishDate ?? .distantPast) < date}
        let endDate = skillQueue.compactMap{$0.queuedSkill.finishDate}.max()
        let skillsCount = skillQueue.count
        let title: Text
        if let timeLeft = endDate?.timeIntervalSinceNow, timeLeft > 0, skillsCount > 0 {
            let s = TimeIntervalFormatter.localizedString(from: timeLeft, precision: .minutes)
            title = Text("SKILL QUEUE: \(s) (\(skillsCount) skills)")
        }
        else {
            title = Text("NO SKILLS IN TRAINING")
        }
        
        
        return Section(header: title) {
            ForEach(skillQueue, id: \.self) { i in
                (try? self.managedObjectContext.from(SDEInvType.self).filter(\SDEInvType.typeID == i.skill.typeID).first()).map { type in
                    SkillCell(type: type, pilot: self.pilot, skillQueueItem: i)
                }
            }
        }
    }
}

struct SkillQueueSection_Previews: PreviewProvider {
    static var previews: some View {
        SkillQueueSection(pilot: .empty)
    }
}
