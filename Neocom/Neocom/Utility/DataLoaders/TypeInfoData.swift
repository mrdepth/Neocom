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
    
    enum Row: Identifiable {
        struct Attribute: Identifiable {
            var id: NSManagedObjectID
            var image: UIImage?
            var title: String
            var subtitle: String
            var targetType: NSManagedObjectID? = nil
            var targetGroup: NSManagedObjectID? = nil
        }
        
        struct Skill: Identifiable {
            var id: NSManagedObjectID
            var image: Image
            var name: String
            var level: Int
            var trainingTime: String?
            var color: UIColor
        }
        
        struct DamageRow: Identifiable {
            var id: NSManagedObjectID
            var damage: Damage
            let percentStyle: Bool
        }
        
        struct Variations: Identifiable {
            var id: String { "Variations" }
            var count: Int
            var predicate: Predictable
        }
        
        struct Mastery: Identifiable {
            var id: NSManagedObjectID
            var typeID: NSManagedObjectID
            var title: String
            var subtitle: String?
            var image: UIImage?
        }
        
        struct MarketHistory: Identifiable {
            var id: String { "MarketHistory" }
            var volume: UIBezierPath
            var median: UIBezierPath
            var donchian: UIBezierPath
            var donchianVisibleRange: CGRect
            var dateRange: ClosedRange<Date>
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
            case let .marketHistory(history):
                return history.id
            case .price:
                return "Price"
            }
        }
        
        case attribute(Attribute)
        case skill(Skill)
        case damage(DamageRow)
        case variations(Variations)
        case mastery(Mastery)
        case marketHistory(MarketHistory)
        case price(Double)
    }
    
    struct Section: Identifiable {
        var id: AnyHashable
        var name: String
        var rows: [Row]
    }
    
    init(type: SDEInvType, esi: ESI, characterID: Int64?, managedObjectContext: NSManagedObjectContext, override attributeValues: [Int: Double]?) {
        esi.image.type(Int(type.typeID), size: .size1024).receive(on: RunLoop.main).sink(receiveCompletion: {_ in}) { [weak self] (result) in
            self?.renderImage = result
        }.store(in: &subscriptions)
        
        if type.marketGroup != nil {
            let typeID = Int(type.typeID)
            esi.markets.prices().get().compactMap {
                $0.first{$0.typeID == typeID}
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
        
        Publishers.CombineLatest($pilot, $price).flatMap { (pilot, price) in
            Future { promise in
                managedObjectContext.perform {
                    promise(.success(self.info(for: managedObjectContext.object(with: type.objectID) as! SDEInvType, pilot: pilot, price: price, managedObjectContext: managedObjectContext, override: attributeValues)))
                }
            }
        }.receive(on: RunLoop.main).sink { [weak self] result in
            self?.sections = result
        }.store(in: &subscriptions)
    }
    
    private var subscriptions = Set<AnyCancellable>()
}

extension TypeInfoData {
    
    private func info(for type: SDEInvType, pilot: Pilot?, price: ESI.MarketPrice?, managedObjectContext: NSManagedObjectContext, override attributeValues: [Int: Double]?) -> [Section] {
        
        let results = managedObjectContext.from(SDEDgmTypeAttribute.self)
            .filter(\SDEDgmTypeAttribute.type == type && \SDEDgmTypeAttribute.attributeType?.published == true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, ascending: true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeID, ascending: true)
            .fetchedResultsController(sectionName: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, cacheName: nil)
        
        var sections = [Section]()
        
        if let price = price?.averagePrice {
            let section = Section(id: "Market",
                    name: NSLocalizedString("Market", comment: "").uppercased(),
                    rows: [.price(price)])
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
                                s += " " + NSLocalizedString("AU/sec", comment: "")
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
        let predicate = \SDEInvType.parentType == what || _self == what
        
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
    
    private func marketInfo(history: [ESI.MarketHistoryItem]) -> Row? {
        guard !history.isEmpty else {return nil}
        guard let date = history.last?.date.addingTimeInterval(-3600 * 24 * 365) else {return nil}
        guard let i = history.firstIndex(where: { $0.date > date }) else { return nil }
        
        let range = history.suffix(from: i).indices
        
        let visibleRange = { () -> ClosedRange<Double> in
            var h2 = 0 as Double
            var h = 0 as Double
            var l2 = 0 as Double
            var l = 0 as Double
            let n = Double(range.count)
            for i in range {
                let item = history[i]
                h += Double(item.highest) / n
                h2 += Double(item.highest * item.highest) / n
                l += Double(item.lowest) / n
                l2 += Double(item.lowest * item.lowest) / n
            }
            let avgl = l
            let avgh = h
            h *= h
            l *= l
            let devh = h < h2 ? sqrt(h2 - h) : 0
            let devl = l < l2 ? sqrt(l2 - l) : 0
            return (avgl - devl * 3)...(avgh + devh * 3)
        }()
        
        let volume = UIBezierPath()
        //            volume.move(to: CGPoint(x: 0, y: 0))
        
        let donchian = UIBezierPath()
        let avg = UIBezierPath()
        
        var x: CGFloat = 0
        var isFirst = true
        
        var v = 0...0 as ClosedRange<Int64>
        var p = 0...0 as ClosedRange<Double>
        let dateRange = history[range.first!].date...history[range.last!].date
        var prevT: TimeInterval?
        
        var lowest = Double.greatestFiniteMagnitude as Double
        var highest = 0 as Double
        
        for i in range {
            let item = history[i]
            if visibleRange.contains(Double(item.lowest)) {
                lowest = min(lowest, Double(item.lowest))
            }
            if visibleRange.contains(Double(item.highest)) {
                highest = max(highest, Double(item.highest))
            }
            
            let t = item.date.timeIntervalSinceReferenceDate
            x = CGFloat(item.date.timeIntervalSinceReferenceDate)
            let lowest = history[max(i - 4, 0)...i].min {
                $0.lowest < $1.lowest
                }!
            let highest = history[max(i - 4, 0)...i].max {
                $0.highest < $1.highest
                }!
            if isFirst {
                avg.move(to: CGPoint(x: x, y: CGFloat(item.average)))
                isFirst = false
            }
            else {
                avg.addLine(to: CGPoint(x: x, y: CGFloat(item.average)))
            }
            if let prevT = prevT {
                volume.append(UIBezierPath(rect: CGRect(x: CGFloat(prevT), y: 0, width: CGFloat(t - prevT), height: CGFloat(item.volume))))
                donchian.append(UIBezierPath(rect: CGRect(x: CGFloat(prevT), y: CGFloat(lowest.lowest), width: CGFloat(t - prevT), height: abs(CGFloat(highest.highest - lowest.lowest)))))
            }
            prevT = t
            
            v = min(v.lowerBound, item.volume)...max(v.upperBound, item.volume)
            p = min(p.lowerBound, Double(lowest.lowest))...max(p.upperBound, Double(highest.highest))
        }
        
        var donchianVisibleRange = donchian.bounds
        if lowest < highest {
            donchianVisibleRange.origin.y = CGFloat(lowest)
            donchianVisibleRange.size.height = CGFloat(highest - lowest)
        }
        
        return .marketHistory(Row.MarketHistory(volume: volume, median: avg, donchian: donchian, donchianVisibleRange: donchianVisibleRange, dateRange: dateRange))
    }
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
            icon = attributeType?.icon?.image?.image
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
//            subtitle = nil
            color = .secondaryLabel
            let trainingTime = item.trainingTime(with: .default)
            subtitle = trainingTime > 0 ? TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil

//            trainingTime = 0
        }
        
        self = .skill(TypeInfoData.Row.Skill(id: skillType.objectID, image: image, name: skillType.typeName ?? "\(skillType.typeID)", level: level, trainingTime: subtitle, color: color))
    }
    
}


extension TypeInfoData.Row.MarketHistory {
    init?(history: [ESI.MarketHistoryItem]) {
        guard !history.isEmpty else {return nil}
        guard let date = history.last?.date.addingTimeInterval(-3600 * 24 * 365) else {return nil}
        guard let i = history.firstIndex(where: { $0.date > date }) else { return nil }
        
        let range = history.suffix(from: i).indices
        
        let visibleRange = { () -> ClosedRange<Double> in
            var h2 = 0 as Double
            var h = 0 as Double
            var l2 = 0 as Double
            var l = 0 as Double
            let n = Double(range.count)
            for i in range {
                let item = history[i]
                h += Double(item.highest) / n
                h2 += Double(item.highest * item.highest) / n
                l += Double(item.lowest) / n
                l2 += Double(item.lowest * item.lowest) / n
            }
            let avgl = l
            let avgh = h
            h *= h
            l *= l
            let devh = h < h2 ? sqrt(h2 - h) : 0
            let devl = l < l2 ? sqrt(l2 - l) : 0
            return (avgl - devl * 3)...(avgh + devh * 3)
        }()
        
        let volume = UIBezierPath()
        //            volume.move(to: CGPoint(x: 0, y: 0))
        
        let donchian = UIBezierPath()
        let avg = UIBezierPath()
        
        var x: CGFloat = 0
        var isFirst = true
        
        var v = 0...0 as ClosedRange<Int64>
        var p = 0...0 as ClosedRange<Double>
        let dateRange = history[range.first!].date...history[range.last!].date
        var prevT: TimeInterval?
        
        var lowest = Double.greatestFiniteMagnitude as Double
        var highest = 0 as Double
        
        for i in range {
            let item = history[i]
            if visibleRange.contains(Double(item.lowest)) {
                lowest = min(lowest, Double(item.lowest))
            }
            if visibleRange.contains(Double(item.highest)) {
                highest = max(highest, Double(item.highest))
            }
            
            let t = item.date.timeIntervalSinceReferenceDate
            x = CGFloat(item.date.timeIntervalSinceReferenceDate)
            let lowest = history[max(i - 4, 0)...i].min {
                $0.lowest < $1.lowest
                }!
            let highest = history[max(i - 4, 0)...i].max {
                $0.highest < $1.highest
                }!
            if isFirst {
                avg.move(to: CGPoint(x: x, y: CGFloat(item.average)))
                isFirst = false
            }
            else {
                avg.addLine(to: CGPoint(x: x, y: CGFloat(item.average)))
            }
            if let prevT = prevT {
                volume.append(UIBezierPath(rect: CGRect(x: CGFloat(prevT), y: 0, width: CGFloat(t - prevT), height: CGFloat(item.volume))))
                donchian.append(UIBezierPath(rect: CGRect(x: CGFloat(prevT), y: CGFloat(lowest.lowest), width: CGFloat(t - prevT), height: abs(CGFloat(highest.highest - lowest.lowest)))))
            }
            prevT = t
            
            v = min(v.lowerBound, item.volume)...max(v.upperBound, item.volume)
            p = min(p.lowerBound, Double(lowest.lowest))...max(p.upperBound, Double(highest.highest))
        }
        
        var donchianVisibleRange = donchian.bounds
        if lowest < highest {
            donchianVisibleRange.origin.y = CGFloat(lowest)
            donchianVisibleRange.size.height = CGFloat(highest - lowest)
        }
        
        self.volume = volume
        self.median = avg
        self.donchian = donchian
        self.donchianVisibleRange = donchianVisibleRange
        self.dateRange = dateRange
    }
}
