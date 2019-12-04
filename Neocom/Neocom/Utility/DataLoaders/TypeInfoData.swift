//
//  TypeInfoData.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/3/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import CoreData
import Expressible
import SwiftUI

class TypeInfoData: ObservableObject {
    @Published var renderImage: UIImage?
    @Published var pilot: Pilot?
    
    enum Row: Identifiable {
        struct Attribute: Identifiable {
            var id: NSManagedObjectID
            var image: UIImage?
            var title: String
            var subtitle: String
            var targetType: NSManagedObjectID?
            var targetGroup: NSManagedObjectID?
        }
        
        struct Skill: Identifiable {
            var id: Int
            var image: Image
            var name: String
            var level: Int
            var subtitle: String?
            var color: UIColor
            var targetType: NSManagedObjectID?
        }
        
        var id: AnyHashable {
            switch self {
            case let .attribute(attribute):
                return attribute.id
            case let .skill(skill, _):
                return skill.id
            }
        }
        
        case attribute(Attribute)
        indirect case skill(Skill, [Row])
    }
    
    init(type: SDEInvType, esi: ESI, characterID: Int64?, managedObjectContext: NSManagedObjectContext) {
        esi.image.type(Int(type.typeID), size: .size1024).receive(on: RunLoop.main).sink(receiveCompletion: {_ in}) { [weak self] (result) in
            self?.renderImage = result
        }.store(in: &subscriptions)
        
        if let characterID = characterID {
            Pilot.load(esi.characters.characterID(Int(characterID)), in: managedObjectContext)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: {_ in }) { [weak self] (result) in
                    self?.pilot = result
            }.store(in: &subscriptions)
        }
        
        $pilot.flatMap { pilot in
            Future { promise in
                managedObjectContext.perform {
                    promise(.success(1))
                }
            }
        }.receive(on: RunLoop.main).sink { result in
        }.store(in: &subscriptions)
    }
    
    private var subscriptions = Set<AnyCancellable>()
}


extension TypeInfoData.Row {
    
    init(_ attribute: SDEDgmTypeAttribute) {
        let title: String
        
        if let displayName = attribute.attributeType?.displayName, !displayName.isEmpty {
            title = displayName
        }
        else if let attributeName = attribute.attributeType?.attributeName, !attributeName.isEmpty {
            title = attributeName
        }
        else {
            title = "\(attribute.attributeType?.attributeID ?? 0)"
        }

        
        let unitID = (attribute.attributeType?.unit?.unitID).flatMap {SDEUnitID(rawValue: $0)} ?? .none
        var icon: UIImage?
        
        let subtitle: String
        
        func toString(_ value: Double) -> String {
            var s = UnitFormatter.localizedString(from: value, unit: .none, style: .long)
            if let unit = attribute.attributeType?.unit?.displayName {
                s += " " + unit
            }
            return s
        }
        
        
        let value = attribute.value
        var targetType: NSManagedObjectID?
        var targetGroup: NSManagedObjectID?
        
        switch unitID {
        case .attributeID:
            let attributeType = try? attribute.managedObjectContext?.from(SDEDgmAttributeType.self)
                .filter(\SDEDgmAttributeType.attributeID == Int(value)).first()
            subtitle = attributeType?.displayName ?? attributeType?.attributeName ?? toString(value)
        case .groupID:
            let group = try? attribute.managedObjectContext?.from(SDEInvGroup.self)
                .filter(\SDEInvGroup.groupID == Int(value)).first()
            subtitle = group?.groupName ?? toString(value)
            icon = attribute.attributeType?.icon?.image?.image ?? group?.icon?.image?.image
            targetGroup = group?.objectID
        case .typeID:
            let type = try? attribute.managedObjectContext?.from(SDEInvType.self)
                .filter(\SDEInvType.typeID == Int(value)).first()
            subtitle = type?.typeName ?? toString(value)
            icon = type?.icon?.image?.image ?? attribute.attributeType?.icon?.image?.image
            targetType = type?.objectID
        case .sizeClass:
            subtitle = SDERigSize(rawValue: Int(value))?.description ?? String(describing: Int(value))
        case .bonus:
            subtitle = "+" + UnitFormatter.localizedString(from: value, unit: .none, style: .long)
        case .boolean:
            subtitle = Int(value) == 0 ? NSLocalizedString("No", comment: "") : NSLocalizedString("Yes", comment: "")
        case .inverseAbsolutePercent, .inversedModifierPercent:
            subtitle = toString((1.0 - value) * 100.0)
        case .modifierPercent:
            subtitle = toString((value - 1.0) * 100.0)
        case .absolutePercent:
            subtitle = toString(value * 100.0)
        case .milliseconds:
            subtitle = toString(value / 1000.0)
        default:
            subtitle = toString(value)
        }
        
        
        self = .attribute(Attribute(id: attribute.objectID,
                                    image: icon ?? attribute.attributeType?.icon?.image?.image,
                                    title: title,
                                    subtitle: subtitle,
                                    targetType: targetType,
                                    targetGroup: targetGroup))
    }
    
    init?(_ skillType: SDEInvType, level: Int, pilot: Pilot?) {
        guard let skill = Pilot.Skill(type: skillType) else {return nil}
        let trainedSkill = pilot?.trainedSkills[Int(skillType.typeID)]
        
        let item = TrainingQueue.Item(skill: skill, targetLevel: level, startSP: Int(trainedSkill?.skillpointsInSkill ?? 0))
        let image: Image
        let subtitle: String?
        let color: UIColor
        
        if let pilot = pilot {
            if let trainedSkill = trainedSkill, trainedSkill.trainedSkillLevel >= level {
                image = Image(systemName: "checkmark.circle")
                subtitle = nil
                color = .label
//                trainingTime = 0
            }
            else {
                image = Image(systemName: "circle")
                
                let trainingTime = item.trainingTime(with: pilot.attributes)
                subtitle = trainingTime > 0 ? TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
                color = trainingTime > 0 ? .secondaryLabel : .label
//                self.trainingTime = trainingTime
            }
        }
        else {
            image = Image(systemName: "xmark.circle")
            subtitle = nil
            color = .label
//            trainingTime = 0
        }
        
        let requirements = (skillType.requiredSkills?.array as? [SDEIndRequiredSkill])?.compactMap{TypeInfoData.Row($0.skillType!, level: Int($0.skillLevel), pilot: pilot)}
        
        self = .skill(TypeInfoData.Row.Skill(id: 0, image: image, name: skillType.typeName ?? "\(skillType.typeID)", level: level, subtitle: subtitle, color: color, targetType: skillType.objectID), requirements ?? [])
    }
}
