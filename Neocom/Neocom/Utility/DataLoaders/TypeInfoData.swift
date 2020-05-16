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
    @Published var sections: [Section] = []
    @Published var price: ESI.MarketPrice?
//    @Published var marketHistory: [ESI.MarketHistoryItem]?
    
    enum Row: Identifiable {
        struct Attribute: Identifiable {
            var id: AnyHashable
            var image: UIImage?
            var title: String
            var subtitle: String
            var targetType: NSManagedObjectID? = nil
            var targetGroup: NSManagedObjectID? = nil
        }
        
        struct Skill: Identifiable {
            var id: AnyHashable { return objectID }
            var objectID: NSManagedObjectID
            var image: Image
            var name: String
            var level: Int
            var trainingTime: String?
            var color: UIColor
        }
        
        struct DamageRow: Identifiable {
            var id: AnyHashable
            var damage: Damage
            let percentStyle: Bool
        }
        
        struct Variations: Identifiable {
            var id: String { "Variations" }
            var count: Int
            var predicate: PredicateProtocol
        }
        
        struct Mastery: Identifiable {
            var id: AnyHashable
            var typeID: NSManagedObjectID
            var title: String
            var subtitle: String?
            var image: UIImage?
        }
        
        var id: AnyHashable {
            switch self {
            case let .attribute(attribute):
                return attribute.id
            case let .skill(skill):
                return skill.id
            case let .damage(damage):
                return damage.id
            case let .variations(variations):
                return variations.id
            case let .mastery(mastery):
                return mastery.id
            case .marketHistory:
                return "MarketHistory"
            case .price:
                return "Price"
            }
        }
        
        case attribute(Attribute)
        case skill(Skill)
        case damage(DamageRow)
        case variations(Variations)
        case mastery(Mastery)
        case marketHistory
        case price(Double)
    }
    
    struct Section: Identifiable {
        var id: AnyHashable
        var name: String
        var rows: [Row]
    }
    
    init(type: SDEInvType, esi: ESI, characterID: Int64?, marketRegionID: Int, managedObjectContext: NSManagedObjectContext, override attributeValues: [Int: Double]?) {
        esi.image.type(Int(type.typeID), size: .size1024).receive(on: RunLoop.main).sink(receiveCompletion: {_ in}) { [weak self] (result) in
            self?.renderImage = result
        }.store(in: &subscriptions)
        
        if type.marketGroup != nil {
            let typeID = Int(type.typeID)
            esi.markets.prices().get().compactMap {
                $0.value.first{$0.typeID == typeID}
            }.receive(on: RunLoop.main)
            .sink(receiveCompletion: {_ in }) { [weak self] result in
                self?.price = result
            }.store(in: &subscriptions)
        }
        
        if let characterID = characterID {
            Pilot.load(esi.characters.characterID(Int(characterID)), in: managedObjectContext)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: {_ in }) { [weak self] result in
                    self?.pilot = result
            }.store(in: &subscriptions)
        }
        
        /*Publishers.CombineLatest($pilot, $price).flatMap { (pilot, price) in
            Future { promise in
                managedObjectContext.perform {
                    let localType = managedObjectContext.object(with: type.objectID) as! SDEInvType
                    promise(.success(self.info(for: localType, pilot: pilot, price: price, managedObjectContext: managedObjectContext, override: attributeValues)))
                }
            }
        }.receive(on: RunLoop.main).sink { [weak self] result in
            self?.sections = result
        }.store(in: &subscriptions)*/
    }
    
    private var subscriptions = Set<AnyCancellable>()
}

extension TypeInfoData {
    
    private func info(for type: SDEInvType, pilot: Pilot?, price: ESI.MarketPrice?, managedObjectContext: NSManagedObjectContext, override attributeValues: [Int: Double]?) -> [Section] {

        var sections: [Section]
        
        let categoryID = (type.group?.category?.categoryID).flatMap { SDECategoryID(rawValue: $0)}
        switch categoryID {
        case .entity:
            sections = npcInfo(for: type, managedObjectContext: managedObjectContext)
        default:
            if type.wormhole != nil {
                sections = whInfo(for: type, managedObjectContext: managedObjectContext)
            }
            else {
                sections = basicInfo(for: type, pilot: pilot, price: price, managedObjectContext: managedObjectContext, override: attributeValues)
            }
        }

        
        if type.marketGroup != nil {
            let rows = [(price?.averagePrice).map{Row.price($0)}, .marketHistory].compactMap{$0}
            let section = Section(id: "Market",
                    name: NSLocalizedString("Market", comment: "").uppercased(),
                    rows: rows)
            sections.insert(section, at: 0)
        }
        return sections
    }
    
    private func basicInfo(for type: SDEInvType, pilot: Pilot?, price: ESI.MarketPrice?, managedObjectContext: NSManagedObjectContext, override attributeValues: [Int: Double]?) -> [Section] {
        
        let results = managedObjectContext.from(SDEDgmTypeAttribute.self)
            .filter(/\SDEDgmTypeAttribute.type == type && /\SDEDgmTypeAttribute.attributeType?.published == true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, ascending: true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeID, ascending: true)
            .fetchedResultsController(sectionName: /\SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, cacheName: nil)
        
        var sections = [Section]()
		
		if type.marketGroup != nil {
			let rows = [(price?.averagePrice).map{Row.price($0)}, .marketHistory].compactMap{$0}
            let section = Section(id: "Market",
                    name: NSLocalizedString("Market", comment: "").uppercased(),
                    rows: rows)
            sections.append(section)
		}
        
        if let variations = variations(for: type) {
            sections.append(variations)
        }
        if let mastery = masteries(for: type, pilot: pilot) {
            sections.append(mastery)
        }
        
        do {
            try results.performFetch()
            sections.append(contentsOf:
                results.sections?.compactMap { section -> Section? in
                    guard let attributeCategory = (section.objects?.first as? SDEDgmTypeAttribute)?.attributeType?.attributeCategory else {return nil}
                    
                    if SDEAttributeCategoryID(rawValue: attributeCategory.categoryID) == .requiredSkills {
                        return self.requiredSkills(for: type, pilot: pilot)
                        //                        return section
                        //                        guard let section = requiredSkillsPresentation(for: type, character: character, context: context) else {return nil}
                        //                        return section.asAnyItem
                    }
                    else {
                        let sectionTitle: String = SDEAttributeCategoryID(rawValue: attributeCategory.categoryID) == .null ? NSLocalizedString("Other", comment: "") : attributeCategory.categoryName ?? NSLocalizedString("Other", comment: "")
                        
                        var rows = [Row]()
                        
                        var damageRow: Row.DamageRow?
                        func damage(_ attribute: SDEDgmTypeAttribute, update: (inout Row.DamageRow) -> Void) {
                            if damageRow == nil {
                                damageRow = Row.DamageRow(id: attribute.objectID, damage: Damage(), percentStyle: false)
                            }
                            update(&damageRow!)
                        }
                        
                        var resistanceRow: Row.DamageRow?
                        func resistance(_ attribute: SDEDgmTypeAttribute, update: (inout Row.DamageRow) -> Void) {
                            if resistanceRow == nil {
                                resistanceRow = Row.DamageRow(id: attribute.objectID, damage: Damage(), percentStyle: true)
                            }
                            update(&resistanceRow!)
                        }
                        
                        (section.objects as? [SDEDgmTypeAttribute])?.forEach { attribute in
                            let value = attributeValues?[Int(attribute.attributeType!.attributeID)] ?? attribute.value
                            
                            switch SDEAttributeID(rawValue: attribute.attributeType!.attributeID) {
                            case .emDamageResonance?, .armorEmDamageResonance?, .shieldEmDamageResonance?,
                                 .hullEmDamageResonance?, .passiveArmorEmDamageResonance?, .passiveShieldEmDamageResonance?:
                                resistance(attribute) { row in
                                    row.damage.em = max(row.damage.em, 1 - value)
                                }
                            case .thermalDamageResonance?, .armorThermalDamageResonance?, .shieldThermalDamageResonance?,
                                 .hullThermalDamageResonance?, .passiveArmorThermalDamageResonance?, .passiveShieldThermalDamageResonance?:
                                resistance(attribute) { row in
                                    row.damage.thermal = max(row.damage.thermal, 1 - value)
                                }
                            case .kineticDamageResonance?, .armorKineticDamageResonance?, .shieldKineticDamageResonance?,
                                 .hullKineticDamageResonance?, .passiveArmorKineticDamageResonance?, .passiveShieldKineticDamageResonance?:
                                resistance(attribute) { row in
                                    row.damage.kinetic = max(row.damage.kinetic, 1 - value)
                                }
                            case .explosiveDamageResonance?, .armorExplosiveDamageResonance?, .shieldExplosiveDamageResonance?,
                                 .hullExplosiveDamageResonance?, .passiveArmorExplosiveDamageResonance?, .passiveShieldExplosiveDamageResonance?:
                                resistance(attribute) { row in
                                    row.damage.explosive = max(row.damage.explosive, 1 - value)
                                }
                            case .emDamage?:
                                damage(attribute) { row in
                                    row.damage.em = value
                                }
                            case .thermalDamage?:
                                damage(attribute) { row in
                                    row.damage.thermal = value
                                }
                            case .kineticDamage?:
                                damage(attribute) { row in
                                    row.damage.kinetic = value
                                }
                            case .explosiveDamage?:
                                damage(attribute) { row in
                                    row.damage.explosive = value
                                }
                                
                            case .warpSpeedMultiplier?:
                                guard let attributeType = attribute.attributeType else {return}
                                
                                let baseWarpSpeed =  attributeValues?[Int(SDEAttributeID.baseWarpSpeed.rawValue)] ?? type[SDEAttributeID.baseWarpSpeed]?.value ?? 1.0
                                var s = UnitFormatter.localizedString(from: Double(value * baseWarpSpeed), unit: .none, style: .long)
                                s += " " + NSLocalizedString("AU/s", comment: "")
                                rows.append(.attribute(Row.Attribute(id: attribute.objectID,
                                                                     image: attributeType.icon?.image?.image,
                                                                     title: NSLocalizedString("Warp Speed", comment: ""),
                                                                     subtitle: s)))
                            default:
                                rows.append(Row(attribute))
                            }
                        }
                        
                        if let resistanceRow = resistanceRow {
                            rows.append(.damage(resistanceRow))
                            
                        }
                        if let damageRow = damageRow {
                            rows.append(.damage(damageRow))
                        }
                        guard !rows.isEmpty else {return nil}
                        return Section(id: attributeCategory.objectID, name: sectionTitle.uppercased(), rows: rows)
                    }
                    } ?? [])
        }
        catch {
        }
        
        return sections
    }
    
    private func requiredSkills(for type: SDEInvType, pilot: Pilot?) -> Section? {
        var skills = [SDEInvType: (level: Int16, order: Int)]()
        func enumerate(_ type: SDEInvType, _ order: Int) {
            (type.requiredSkills?.array as? [SDEInvTypeRequiredSkill])?.forEach { i in
                guard let skillType = i.skillType else {return}
                if var value = skills[skillType] {
                    value.level = max(value.level, i.skillLevel)
                    skills[skillType] = value
                }
                else {
                    skills[skillType] = (i.skillLevel, order)
                }
                enumerate(skillType, order + 1)
            }
        }
        enumerate(type, 0)
        
        let rows = skills.sorted{$0.value.order < $1.value.order}.compactMap {
            TypeInfoData.Row($0.key, level: Int($0.value.level), pilot: pilot)
        }
        let trainingQueue = TrainingQueue(pilot: pilot ?? .empty)
        trainingQueue.addRequiredSkills(for: type)
        let time = trainingQueue.trainingTime()
        guard !rows.isEmpty else {return nil}
        let title = time > 0 ? NSLocalizedString("Required Skills", comment: "").uppercased() + ": " + TimeIntervalFormatter.localizedString(from: time, precision: .seconds) : NSLocalizedString("Required Skills", comment: "").uppercased()
        return Section(id: "RequiredSkills", name: title, rows: rows)
    }
    
    private func variations(for type: SDEInvType) -> Section? {
        guard type.parentType != nil || (type.variations?.count ?? 0) > 0 else {return nil}
        let n = max(type.variations?.count ?? 0, type.parentType?.variations?.count ?? 0) + 1
        let what = type.parentType ?? type
        let predicate = /\SDEInvType.parentType == what || /\SDEInvType.self == what
        
        return Section(id: "VariationsSection",
                       name: NSLocalizedString("Variations", comment: "").uppercased(),
                       rows: [.variations(TypeInfoData.Row.Variations(count: n, predicate: predicate))])
    }
    
    private func masteries(for type: SDEInvType, pilot: Pilot?) -> Section? {
        var masteries = [Int: [SDECertMastery]]()
        
        (type.certificates?.allObjects as? [SDECertCertificate])?.forEach { certificate in
            (certificate.masteries?.array as? [SDECertMastery])?.forEach { mastery in
                masteries[Int(mastery.level?.level ?? 0), default: []].append(mastery)
            }
        }
        
        let unclaimedIcon = try? type.managedObjectContext?.fetch(SDEEveIcon.named(.mastery(nil))).first
        
        let pilot = pilot ?? .empty
        
        let rows = masteries.sorted {$0.key < $1.key}.compactMap { (key, array) -> Row? in
            guard let mastery = array.first else {return nil}
            guard let level = mastery.level else {return nil}
            
            let trainingQueue = TrainingQueue(pilot: pilot)
            array.forEach {trainingQueue.add($0)}
            let trainingTime = trainingQueue.trainingTime()
            let title = NSLocalizedString("Level", comment: "").uppercased() + " \(String(roman: key + 1))"
            let subtitle = trainingTime > 0 ? TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
            let icon = trainingTime > 0 ? unclaimedIcon : level.icon
            
            return Row.mastery(TypeInfoData.Row.Mastery(id: level.objectID, typeID: type.objectID, title: title, subtitle: subtitle, image: icon?.image?.image))
        }
        
        guard !rows.isEmpty else {return nil}
        return Section(id: "Mastery", name: NSLocalizedString("Mastery", comment: "").uppercased(), rows: rows)
        //        return Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Mastery", comment: "").uppercased()), diffIdentifier: "Mastery", expandIdentifier: "Mastery", treeController: view?.treeController, children: rows)
    }
    
    private func npcInfo(for type: SDEInvType, managedObjectContext: NSManagedObjectContext) -> [Section] {
        
        let results = managedObjectContext.from(SDEDgmTypeAttribute.self)
            .filter(/\SDEDgmTypeAttribute.type == type && /\SDEDgmTypeAttribute.attributeType?.published == true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, ascending: true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeID, ascending: true)
            .fetchedResultsController(sectionName: /\SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, cacheName: nil)
        
        var sections = [Section]()

        do {
            try results.performFetch()
            var resultSections = results.sections
            _ = resultSections?.partition{($0.objects?.first as? SDEDgmTypeAttribute)?.attributeType?.attributeCategory?.categoryID != SDEAttributeCategoryID.entityRewards.rawValue}
            
            sections.append(contentsOf:
                resultSections?.compactMap { section -> Section? in
                    guard let attributeCategory = (section.objects?.first as? SDEDgmTypeAttribute)?.attributeType?.attributeCategory else {return nil}
                    
                    let categoryID = SDEAttributeCategoryID(rawValue: attributeCategory.categoryID)
                    
                    let sectionTitle: String = categoryID == .null ? NSLocalizedString("Other", comment: "") : attributeCategory.categoryName ?? NSLocalizedString("Other", comment: "")
                    
                    var rows = [Row]()

                    switch categoryID {
                    case .turrets?:
                        guard let speed = type[SDEAttributeID.speed] else {break}
                        let damageMultiplier = type[SDEAttributeID.damageMultiplier]?.value ?? 1
                        let maxRange = type[SDEAttributeID.maxRange]?.value ?? 0
                        let falloff = type[SDEAttributeID.falloff]?.value ?? 0
                        let duration: Double = speed.value / 1000
                        
                        let em = type[SDEAttributeID.emDamage]?.value ?? 0
                        let explosive = type[SDEAttributeID.explosiveDamage]?.value ?? 0
                        let kinetic = type[SDEAttributeID.kineticDamage]?.value ?? 0
                        let thermal = type[SDEAttributeID.thermalDamage]?.value ?? 0
                        let total = (em + explosive + kinetic + thermal) * damageMultiplier
                        
                        let interval = duration > 0 ? duration : 1
                        let dps = total / interval
                        
                        rows.append(.damage(TypeInfoData.Row.DamageRow(id: "TurretsDamage",
                                                                       damage: Damage(em: em * damageMultiplier,
                                                                       thermal: thermal * damageMultiplier,
                                                                       kinetic: kinetic * damageMultiplier,
                                                                       explosive: explosive * damageMultiplier),
                                                                       percentStyle: false)))
                        
                        rows.append(.attribute(TypeInfoData.Row.Attribute(id: "TurretsDPS",
                                                                          image: #imageLiteral(resourceName: "turrets"),
                                                                          title: NSLocalizedString("Damage per Second", comment: "").uppercased(),
                                                                          subtitle: UnitFormatter.localizedString(from: dps, unit: .none, style: .long))))

                        rows.append(.attribute(TypeInfoData.Row.Attribute(id: "TurretsRoF",
                                                                          image: #imageLiteral(resourceName: "rateOfFire"),
                                                                          title: NSLocalizedString("Rate of Fire", comment: "").uppercased(),
                                                                          subtitle: TimeIntervalFormatter.localizedString(from: TimeInterval(duration), precision: .seconds))))

                        rows.append(.attribute(TypeInfoData.Row.Attribute(id: "TurretsOptimal",
                                                                          image: #imageLiteral(resourceName: "rateOfFire"),
                                                                          title: NSLocalizedString("Optimal Range", comment: "").uppercased(),
                                                                          subtitle: UnitFormatter.localizedString(from: maxRange, unit: .meter, style: .long))))

                        rows.append(.attribute(TypeInfoData.Row.Attribute(id: "TurretsFalloff",
                                                                          image: #imageLiteral(resourceName: "falloff"),
                                                                          title: NSLocalizedString("Falloff", comment: "").uppercased(),
                                                                          subtitle: UnitFormatter.localizedString(from: falloff, unit: .meter, style: .long))))
                        
                    case .missile?:
                        guard let attribute = type[SDEAttributeID.entityMissileTypeID], let missile = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(attribute.value)).first() else {break}
                        
                        rows.append(.attribute(TypeInfoData.Row.Attribute(id: attribute.objectID,
                                                                          image: missile.uiImage,
                                                                          title: NSLocalizedString("Missile", comment: "").uppercased(),
                                                                          subtitle: missile.typeName ?? "",
                                                                          targetType: missile.objectID)))

                        let duration: Double = (type[SDEAttributeID.missileLaunchDuration]?.value ?? 1000) / 1000
                        let damageMultiplier = type[SDEAttributeID.missileDamageMultiplier]?.value ?? 1
                        let velocityMultiplier = type[SDEAttributeID.missileEntityVelocityMultiplier]?.value ?? 1
                        let flightTimeMultiplier = type[SDEAttributeID.missileEntityFlightTimeMultiplier]?.value ?? 1
                        
                        let em = missile[SDEAttributeID.emDamage]?.value ?? 0
                        let explosive = missile[SDEAttributeID.explosiveDamage]?.value ?? 0
                        let kinetic = missile[SDEAttributeID.kineticDamage]?.value ?? 0
                        let thermal = missile[SDEAttributeID.thermalDamage]?.value ?? 0
                        let total = (em + explosive + kinetic + thermal) * damageMultiplier
                        
                        let velocity: Double = (missile[SDEAttributeID.maxVelocity]?.value ?? 0) * velocityMultiplier
                        let flightTime: Double = (missile[SDEAttributeID.explosionDelay]?.value ?? 1) * flightTimeMultiplier / 1000
                        let agility: Double = missile[SDEAttributeID.agility]?.value ?? 0
                        let mass = missile.mass
                        
                        let accelTime = min(flightTime, mass * agility / 1000000.0)
                        let duringAcceleration = velocity / 2 * accelTime
                        let fullSpeed = velocity * (flightTime - accelTime)
                        let optimal = duringAcceleration + fullSpeed;
                        
                        let interval = duration > 0 ? duration : 1
                        let dps = total / interval

                        rows.append(.damage(TypeInfoData.Row.DamageRow(id: "MissilesDamage",
                                                                       damage: Damage(em: em * damageMultiplier,
                                                                       thermal: thermal * damageMultiplier,
                                                                       kinetic: kinetic * damageMultiplier,
                                                                       explosive: explosive * damageMultiplier),
                                                                       percentStyle: false)))

                        rows.append(.attribute(TypeInfoData.Row.Attribute(id: "MissilesDPS",
                                                                          image: #imageLiteral(resourceName: "launchers"),
                                                                          title: NSLocalizedString("Damage per Second", comment: "").uppercased(),
                                                                          subtitle: UnitFormatter.localizedString(from: dps, unit: .none, style: .long))))

                        rows.append(.attribute(TypeInfoData.Row.Attribute(id: "MissilesRoF",
                                                                          image: #imageLiteral(resourceName: "rateOfFire"),
                                                                          title: NSLocalizedString("Rate of Fire", comment: "").uppercased(),
                                                                          subtitle: TimeIntervalFormatter.localizedString(from: TimeInterval(duration), precision: .seconds))))

                        rows.append(.attribute(TypeInfoData.Row.Attribute(id: "MissilesOptimal",
                                                                          image: #imageLiteral(resourceName: "targetingRange"),
                                                                          title: NSLocalizedString("Optimal Range", comment: "").uppercased(),
                                                                          subtitle: UnitFormatter.localizedString(from: optimal, unit: .meter, style: .long))))

                        
                    default:
                        
                        var resistanceRow: Row.DamageRow?
                        func resistance(_ attribute: SDEDgmTypeAttribute, update: (inout Row.DamageRow) -> Void) {
                            if resistanceRow == nil {
                                resistanceRow = Row.DamageRow(id: attribute.objectID, damage: Damage(), percentStyle: true)
                            }
                            update(&resistanceRow!)
                        }

                        
                        (section.objects as? [SDEDgmTypeAttribute])?.forEach { attribute in
                            let value = attribute.value
                            
                            switch SDEAttributeID(rawValue: attribute.attributeType!.attributeID) {
                            case .emDamageResonance?, .armorEmDamageResonance?, .shieldEmDamageResonance?,
                                 .hullEmDamageResonance?, .passiveArmorEmDamageResonance?, .passiveShieldEmDamageResonance?:
                                resistance(attribute) { row in
                                    row.damage.em = max(row.damage.em, 1 - value)
                                }

                            case .thermalDamageResonance?, .armorThermalDamageResonance?, .shieldThermalDamageResonance?,
                                 .hullThermalDamageResonance?, .passiveArmorThermalDamageResonance?, .passiveShieldThermalDamageResonance?:
                                resistance(attribute) { row in
                                    row.damage.thermal = max(row.damage.thermal, 1 - value)
                                }
                            case .kineticDamageResonance?, .armorKineticDamageResonance?, .shieldKineticDamageResonance?,
                                 .hullKineticDamageResonance?, .passiveArmorKineticDamageResonance?, .passiveShieldKineticDamageResonance?:
                                resistance(attribute) { row in
                                    row.damage.kinetic = max(row.damage.kinetic, 1 - value)
                                }
                            case .explosiveDamageResonance?, .armorExplosiveDamageResonance?, .shieldExplosiveDamageResonance?,
                                 .hullExplosiveDamageResonance?, .passiveArmorExplosiveDamageResonance?, .passiveShieldExplosiveDamageResonance?:
                                resistance(attribute) { row in
                                    row.damage.explosive = max(row.damage.explosive, 1 - value)
                                }
                            default:
                                rows.append(Row(attribute))
                            }
                        }
                        
                        if let resistanceRow = resistanceRow {
                            rows.append(.damage(resistanceRow))
                        }

                        if categoryID == .shield {
                            if let capacity = type[SDEAttributeID.shieldCapacity]?.value,
                                let rechargeRate = type[SDEAttributeID.shieldRechargeRate]?.value,
                                rechargeRate > 0 && capacity > 0 {
                                let passive = 10.0 / (rechargeRate / 1000.0) * 0.5 * (1 - 0.5) * capacity
                            
                                rows.append(.attribute(TypeInfoData.Row.Attribute(id: "ShieldRecharge",
                                                                                  image: #imageLiteral(resourceName: "shieldRecharge"),
                                                                                  title: NSLocalizedString("Passive Recharge Rate", comment: "").uppercased(),
                                                                                  subtitle: UnitFormatter.localizedString(from: passive, unit: .hpPerSecond, style: .long))))
                            }
                            
                            if let amount = type[SDEAttributeID.entityShieldBoostAmount]?.value,
                                let duration = type[SDEAttributeID.entityShieldBoostDuration]?.value,
                                duration > 0 && amount > 0 {
                                
                                let chance = (type[SDEAttributeID.entityShieldBoostDelayChance] ??
                                    type[SDEAttributeID.entityShieldBoostDelayChanceSmall] ??
                                    type[SDEAttributeID.entityShieldBoostDelayChanceMedium] ??
                                    type[SDEAttributeID.entityShieldBoostDelayChanceLarge])?.value ?? 0
                                
                                let repair = amount / (duration * (1 + chance) / 1000.0)

                                rows.append(.attribute(TypeInfoData.Row.Attribute(id: "ShieldBooster",
                                                                                  image: #imageLiteral(resourceName: "shieldBooster"),
                                                                                  title: NSLocalizedString("Repair Rate", comment: "").uppercased(),
                                                                                  subtitle: UnitFormatter.localizedString(from: repair, unit: .hpPerSecond, style: .long))))
                            }
                        }
                        else if categoryID == .armor {
                            if let amount = type[SDEAttributeID.entityArmorRepairAmount]?.value,
                                let duration = type[SDEAttributeID.entityArmorRepairDuration]?.value,
                                duration > 0 && amount > 0 {
                                
                                let chance = (type[SDEAttributeID.entityArmorRepairDelayChance] ??
                                    type[SDEAttributeID.entityArmorRepairDelayChanceSmall] ??
                                    type[SDEAttributeID.entityArmorRepairDelayChanceMedium] ??
                                    type[SDEAttributeID.entityArmorRepairDelayChanceLarge])?.value ?? 0
                                
                                let repair = amount / (duration * (1 + chance) / 1000.0)
                                
                                rows.append(.attribute(TypeInfoData.Row.Attribute(id: "ArmorRepair",
                                                                                  image: #imageLiteral(resourceName: "armorRepairer"),
                                                                                  title: NSLocalizedString("Repair Rate", comment: "").uppercased(),
                                                                                  subtitle: UnitFormatter.localizedString(from: repair, unit: .hpPerSecond, style: .long))))
                            }
                        }
                    }
                    
                    guard !rows.isEmpty else {return nil}
                    return Section(id: attributeCategory.objectID, name: sectionTitle.uppercased(), rows: rows)
                    } ?? [])
        }
        catch {
        }
        
        return sections
    }
    
    private func whInfo(for type: SDEInvType, managedObjectContext: NSManagedObjectContext) -> [Section] {
        guard let wh = type.wormhole else {return []}
        var rows = [Row]()
        if wh.targetSystemClass > 0 {
            rows.append(Row.attribute(Row.Attribute(id: "LeadsInto",
                                                    image: UIImage(named: "systems"),
                                                    title: NSLocalizedString("Leads Into", comment: ""),
                                                    subtitle: wh.targetSystemClassDisplayName ?? "")))
        }
        if wh.maxStableTime > 0 {
            let icon = try? managedObjectContext.fetch(SDEEveIcon.named(.custom("22_32_16"))).first
            rows.append(Row.attribute(Row.Attribute(id: "MaximumStableTime",
                                                    image: icon?.image?.image,
                                                    title: NSLocalizedString("Maximum Stable Time", comment: ""),
                                                    subtitle: TimeIntervalFormatter.localizedString(from: TimeInterval(wh.maxStableTime) * 60, precision: .hours))))
            
        }
        if wh.maxStableMass > 0 {
            let icon = try? managedObjectContext.fetch(SDEEveIcon.named(.custom("2_64_10"))).first
            rows.append(Row.attribute(Row.Attribute(id: "MaximumStableMass",
                                                    image: icon?.image?.image,
                                                    title: NSLocalizedString("Maximum Stable Mass", comment: ""),
                                                    subtitle: UnitFormatter.localizedString(from: wh.maxStableMass, unit: .kilogram, style: .long))))
        }
        
        if wh.maxJumpMass > 0 {
            let icon = try? managedObjectContext.fetch(SDEEveIcon.named(.custom("36_64_13"))).first
            rows.append(Row.attribute(Row.Attribute(id: "MaximumJumpMass",
                                                    image: icon?.image?.image,
                                                    title: NSLocalizedString("Maximum Jump Mass", comment: ""),
                                                    subtitle: UnitFormatter.localizedString(from: wh.maxJumpMass, unit: .kilogram, style: .long))))
        }
        
        if wh.maxRegeneration > 0 {
            let icon = try? managedObjectContext.fetch(SDEEveIcon.named(.custom("23_64_3"))).first
            rows.append(Row.attribute(Row.Attribute(id: "MaximumMassRegeneration",
                                                    image: icon?.image?.image,
                                                    title: NSLocalizedString("Maximum Mass Regeneration", comment: ""),
                                                    subtitle: UnitFormatter.localizedString(from: wh.maxRegeneration, unit: .kilogram, style: .long))))
        }
        return [Section(id: "wh", name: "", rows: rows)]
    }

    /*
    private func blueprintInfo(for type: SDEInvType, managedObjectContext: NSManagedObjectContext) -> [Section] {
        let activities = (type.blueprintType?.activities?.allObjects as? [SDEIndActivity])?.sorted {$0.activity!.activityID < $1.activity!.activityID}

        return activities?.map { activity -> Section in
            var rows = [Row]()
            let time = TimeIntervalFormatter.localizedString(from: TimeInterval(activity.time), precision: .seconds)
            let row = Row.attribute(TypeInfoData.Row.Attribute(id: [activity.objectID: "time"],
                                                               image: #imageLiteral(resourceName: "skillRequirementQueued"),
                                                               title: time,
                                                               subtitle: ""))
            
            rows.append(row)
            
            let products = (activity.products?.allObjects as? [SDEIndProduct])?.filter {$0.productType?.typeName != nil}.sorted {$0.productType!.typeName! < $1.productType!.typeName!}.map { product -> Row in
                let title = NSLocalizedString("PRODUCT", comment: "")
                let row = Row.attribute(TypeInfoData.Row.Attribute(id: product.productType!.objectID,
                                                                   image: product.productType!.uiImage,
                                                                   title: title,
                                                                   subtitle: product.productType?.typeName ?? "",
                                                                   targetType: product.productType?.objectID))
                return row
            }
            if let products = products {
                rows.append(contentsOf: products)
            }
            
            let materials = (activity.requiredMaterials?.allObjects as? [SDEIndRequiredMaterial])?.filter {$0.materialType?.typeName != nil}.sorted {$0.materialType!.typeName! < $1.materialType!.typeName!}.map { material -> Row in
                let subtitle = UnitFormatter.localizedString(from: material.quantity, unit: .none, style: .long)
                let image = material.materialType?.uiImage
                
                let row = Row.attribute(TypeInfoData.Row.Attribute(id: material.objectID,
                                                                   image: image,
                                                                   title: material.materialType?.typeName ?? "",
                                                                   subtitle: subtitle,
                                                                   targetType: material.materialType?.objectID))
                return row
            }
            
            if let materials = materials, !materials.isEmpty {
                rows.append(Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("MATERIALS", comment: "")),
                                              diffIdentifier: "\(activity.objectID).materials", treeController: view?.treeController, children: materials).asAnyItem)
            }
            
            if let requiredSkills = requiredSkillsPresentation(for: activity, character: character, context: context) {
                rows.append(requiredSkills.asAnyItem)
            }
            
            return Tree.Item.Section(Tree.Content.Section(title: activity.activity?.activityName?.uppercased()), diffIdentifier: activity.objectID, treeController: view?.treeController, children: rows).asAnyItem
        } ?? []
    }
     */

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
                .filter(/\SDEDgmAttributeType.attributeID == Int32(value)).first()
            icon = attributeType?.icon?.image?.image
            subtitle = attributeType?.displayName ?? attributeType?.attributeName ?? toString(value)
        case .groupID:
            let group = try? attribute.managedObjectContext?.from(SDEInvGroup.self)
                .filter(/\SDEInvGroup.groupID == Int32(value)).first()
            subtitle = group?.groupName ?? toString(value)
            icon = attribute.attributeType?.icon?.image?.image ?? group?.icon?.image?.image
            targetGroup = group?.objectID
        case .typeID:
            let type = try? attribute.managedObjectContext?.from(SDEInvType.self)
                .filter(/\SDEInvType.typeID == Int32(value)).first()
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
//            subtitle = nil
            color = .secondaryLabel
            let trainingTime = item.trainingTime(with: .default)
            subtitle = trainingTime > 0 ? TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil

//            trainingTime = 0
        }
        
        self = .skill(TypeInfoData.Row.Skill(objectID: skillType.objectID, image: image, name: skillType.typeName ?? "\(skillType.typeID)", level: level, trainingTime: subtitle, color: color))
    }
    
}

