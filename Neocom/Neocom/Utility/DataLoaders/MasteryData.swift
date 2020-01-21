//
//  MasteryData.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import CoreData
import Expressible
import SwiftUI

class MasteryData: ObservableObject {
    var sections: [Section]
    
    struct Section: Identifiable {
        var id: SDECertMastery
        var title: String
        var subtitle: String?
        var image: Image
        var color: UIColor
        var skills: [SDECertSkill]
        var trainingQueue: TrainingQueue
    }
	
    init(for type: SDEInvType, with level: SDECertMasteryLevel, pilot: Pilot?) {
//        let pilot = pilot ?? .empty
        let masteries = try? type.managedObjectContext?
            .from(SDECertMastery.self)
            .filter(\SDECertMastery.level == level && (\SDECertMastery.certificate?.types).contains(type))
            .sort(by: \SDECertMastery.certificate?.certificateName, ascending: true)
            .fetch()

        sections = masteries?.compactMap { mastery -> Section? in
            let skills = (mastery.skills?.allObjects as? [SDECertSkill])?.sorted {$0.type!.typeName! < $1.type!.typeName!}
            guard skills?.isEmpty == false else {return nil}
            
            let trainingQueue = TrainingQueue(pilot: pilot ?? .empty)
            trainingQueue.add(mastery)
            let title = mastery.certificate?.certificateName ?? ""
            let trainingTime = trainingQueue.trainingTime()
            let subtitle = trainingTime > 0 ? TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
            
            let image: Image
            let color: UIColor
            if pilot == nil {
                image = Image(systemName: "xmark.circle")
                color = .secondaryLabel
            }
            else if trainingTime > 0 {
                image = Image(systemName: "circle")
                color = .secondaryLabel
            }
            else {
                image = Image(systemName: "checkmark.circle")
                color = .label
            }
            
            return Section(id: mastery, title: title, subtitle: subtitle, image: image, color: color, skills: skills ?? [], trainingQueue: trainingQueue)
        } ?? []
	}
}
