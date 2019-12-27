//
//  TypeInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/2/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible
import Alamofire

struct TypeInfo: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
    @Environment(\.esi) var esi
    @Environment(\.account) var account
    @ObservedObject var typeInfo: Lazy<TypeInfoData> = Lazy()
    
    @UserDefault(key: .marketRegionID)
    var marketRegionID: Int = SDERegionID.default.rawValue
    
    var type: SDEInvType
    var attributeValues: [Int: Double]?
    
    init(type: SDEInvType) {
        self.type = type
    }
    
    private var attributes: FetchedResultsController<SDEDgmTypeAttribute> {
        let controller = managedObjectContext.from(SDEDgmTypeAttribute.self)
            .filter(\SDEDgmTypeAttribute.type == type && \SDEDgmTypeAttribute.attributeType?.published == true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, ascending: true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeID, ascending: true)
            .fetchedResultsController(sectionName: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, cacheName: nil)
        return FetchedResultsController(controller)
    }
    
    private func typeInfoData() -> TypeInfoData {
        let info = TypeInfoData(type: type,
								esi: esi,
								characterID: account?.characterID,
                                marketRegionID: marketRegionID,
								managedObjectContext: backgroundManagedObjectContext,
								override: nil)
        return info
    }
    
    private func cell(for row: TypeInfoData.Row) -> AnyView {
        switch row {
        case let .attribute(attribute):
            return AnyView(EmptyView())
//            return AnyView(TypeInfoAttributeCell(attribute: attribute))
        case let .damage(damage):
            return AnyView(EmptyView())
//            return AnyView(TypeInfoDamageCell(damage: damage))
        case let .skill(skill):
            return AnyView(EmptyView())
//            return AnyView(TypeInfoSkillCell(skill: skill))
        case let .variations(variations):
            return AnyView(EmptyView())
//            return AnyView(TypeInfoVariationsCell(variations: variations))
        case let .mastery(mastery):
            return AnyView(TypeInfoMasteryCell(mastery: mastery))
        case .marketHistory:
			return AnyView(TypeInfoMarketHistoryCell(type: type))
        case let .price(price):
            return AnyView(EmptyView())
//            return AnyView(NavigationLink(destination: TypeMarketOrders(type: type)) {TypeInfoPriceCell(price: price)})
        }
    }
    
    var body: some View {
        let info = self.typeInfo.get(initial: self.typeInfoData())
        let categoryID = (type.group?.category?.categoryID).flatMap { SDECategoryID(rawValue: $0)}
        
        return GeometryReader { geometry in
            List {
                Section {
                    TypeInfoHeader(type: self.type,
                                   renderImage: info.renderImage.map{Image(uiImage: $0)},
                                   preferredMaxLayoutWidth: geometry.size.width - 30).listRowInsets(EdgeInsets())
                }
                
                if self.type.marketGroup != nil {
                    Section(header: Text("MARKET")) {
                        TypeInfoPriceCell(type: self.type)
                        TypeInfoMarketHistoryCell(type: self.type)
                    }
                }
                
                if self.type.parentType != nil || (self.type.variations?.count ?? 0) > 0 {
                    Section(header: Text("VARIATIONS")) {
                        TypeInfoVariationsCell(type: self.type)
                    }
                }

                
                if categoryID == .entity {
                    self.npcInfo()
                }
                else {
                    self.basicInfo(for: info.pilot)
                }
            }.listStyle(GroupedListStyle()).navigationBarTitle("Info")
        }
    }
}

extension TypeInfo {
    private func cell(title: LocalizedStringKey, subtitle: String, image: UIImage?) -> some View {
        HStack {
            image.map{Icon(Image(uiImage: $0))}
            VStack(alignment: .leading) {
                Text(title).font(.footnote)
                Text(subtitle).font(.footnote).foregroundColor(.secondary)
            }
        }
    }
    private func cell(title: String, subtitle: String, image: UIImage?) -> some View {
        HStack {
            image.map{Icon(Image(uiImage: $0))}
            VStack(alignment: .leading) {
                Text(title).font(.footnote)
                Text(subtitle).font(.footnote).foregroundColor(.secondary)
            }
        }
    }
}

extension TypeInfo {
    private func requiredSkills(for pilot: Pilot?) -> some View {

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
            TypeInfoSkillCell(skillType: $0.key, level: Int($0.value.level), pilot: pilot)
        }
        let trainingQueue = TrainingQueue(pilot: pilot ?? .empty)
        trainingQueue.addRequiredSkills(for: type)
        let time = trainingQueue.trainingTime()
        let title = time > 0 ? NSLocalizedString("Required Skills", comment: "").uppercased() + ": " + TimeIntervalFormatter.localizedString(from: time, precision: .seconds) : NSLocalizedString("Required Skills", comment: "").uppercased()

        
        return rows.isEmpty ? nil :
            Section(header: Text(title)) {
                ForEach(rows, id: \.skillType.objectID) {
                    $0
                }
            }
    }
    
    private static let skipAttributeIDs: Set<SDEAttributeID> = {
        Set((damageResonanceAttributes + damageAttributes).flatMap{$0.filter{$0.key != .em}}.map{$0.value})
    }()
    
    private static let damageAttributeIDs: Set<SDEAttributeID> = {
        Set((damageResonanceAttributes + damageAttributes).flatMap{$0.filter{$0.key == .em}}.map{$0.value})
    }()
    
    private func basicInfo(for attribute: SDEDgmTypeAttribute) -> some View {
        let attributeID = (attribute.attributeType?.attributeID).flatMap{SDEAttributeID(rawValue:$0)}
        return Group {
            if attributeID != nil {
                if !Self.skipAttributeIDs.contains(attributeID!) {
                    if Self.damageAttributeIDs.contains(attributeID!) {
                        damageInfo(for: attribute)
                    }
                    else if attributeID! == .warpSpeedMultiplier {
                        warpSpeed(for: attribute)
                    }
                    else {
                        TypeInfoAttributeCell(attribute: attribute)
                    }
                }
            }
            else {
                TypeInfoAttributeCell(attribute: attribute)
            }
        }
    }
    
    private func basicInfo(for section: FetchedResultsController<SDEDgmTypeAttribute>.Section, pilot: Pilot?) -> some View {
        let attributeCategory = section.objects.first?.attributeType?.attributeCategory
        let categoryID = attributeCategory.flatMap{SDEAttributeCategoryID(rawValue: $0.categoryID)}
        let sectionTitle: String = categoryID == .null ? NSLocalizedString("Other", comment: "") : attributeCategory?.categoryName ?? NSLocalizedString("Other", comment: "")
        
        return Group {
            if categoryID == .requiredSkills {
                requiredSkills(for: pilot)
            }
            else {
                Section(header: Text(sectionTitle.uppercased())) {
                    ForEach(section.objects, id: \.objectID) { attribute in
                        self.basicInfo(for: attribute)
                    }
                }
            }
        }

        
    }
    
    private func basicInfo(for pilot: Pilot?) -> some View {
        ForEach(attributes.sections, id: \.name) { section in
            self.basicInfo(for: section, pilot: pilot)
        }
    }
    
    private func warpSpeed(for attribute: SDEDgmTypeAttribute) -> some View {
        let attributeType = attribute.attributeType!
        let value = attributeValues?[Int(attributeType.attributeID)] ?? attribute.value
        
        let baseWarpSpeed = attributeValues?[Int(SDEAttributeID.baseWarpSpeed.rawValue)] ?? type[SDEAttributeID.baseWarpSpeed]?.value ?? 1.0
        var s = UnitFormatter.localizedString(from: Double(value * baseWarpSpeed), unit: .none, style: .long)
        s += " " + NSLocalizedString("AU/sec", comment: "")
        return cell(title: "WARP SPEED", subtitle: s, image: attributeType.icon?.image?.image)
    }
    
    private func damageInfo(for attribute: SDEDgmTypeAttribute) -> TypeInfoDamageCell {
        let attributeID = (attribute.attributeType?.attributeID).flatMap{SDEAttributeID(rawValue:$0)}


        func damage(from attributes: [DamageType: SDEAttributeID]) -> Damage {
            func get(_ type: DamageType) -> Double {
                attributes[type].flatMap{attributeValues?[Int($0.rawValue)] ?? self.type[$0]?.value} ?? 0
            }
            return Damage(em: get(.em), thermal: get(.thermal), kinetic: get(.kinetic), explosive: get(.explosive))
        }
        
        if let attributes = damageAttributes.first(where: {$0[.em] == attributeID}) {
            return TypeInfoDamageCell(damage: damage(from: attributes), percentStyle: false)
            
        }
        else if let attributes = damageResonanceAttributes.first(where: {$0[.em] == attributeID}) {
            return TypeInfoDamageCell(damage: damage(from: attributes), percentStyle: true)
        }
        else {
            return TypeInfoDamageCell(damage: Damage(), percentStyle: false)
        }
    }
    
    private func npcInfo(for section: FetchedResultsController<SDEDgmTypeAttribute>.Section) -> some View {
        let attributeCategory = section.objects.first?.attributeType?.attributeCategory
        let categoryID = attributeCategory.flatMap{SDEAttributeCategoryID(rawValue: $0.categoryID)}
        let sectionTitle: String = categoryID == .null ? NSLocalizedString("Other", comment: "") : attributeCategory?.categoryName ?? NSLocalizedString("Other", comment: "")
        
        func turrets() -> some View {
            func row(speed: Double)  -> some View {
                let damageMultiplier = type[SDEAttributeID.damageMultiplier]?.value ?? 1
                let maxRange = type[SDEAttributeID.maxRange]?.value ?? 0
                let falloff = type[SDEAttributeID.falloff]?.value ?? 0
                let duration: Double = speed / 1000
                
                let em = type[SDEAttributeID.emDamage]?.value ?? 0
                let explosive = type[SDEAttributeID.explosiveDamage]?.value ?? 0
                let kinetic = type[SDEAttributeID.kineticDamage]?.value ?? 0
                let thermal = type[SDEAttributeID.thermalDamage]?.value ?? 0
                let total = (em + explosive + kinetic + thermal) * damageMultiplier
                
                let interval = duration > 0 ? duration : 1
                let dps = total / interval
                
                return Group {
                    TypeInfoDamageCell(damage: Damage(em: em * damageMultiplier,
                                                      thermal: thermal * damageMultiplier,
                                                      kinetic: kinetic * damageMultiplier,
                                                      explosive: explosive * damageMultiplier), percentStyle: false)
                    
                    cell(title: "DAMAGE PER SECOND",
                         subtitle: UnitFormatter.localizedString(from: dps, unit: .none, style: .long),
                         image: #imageLiteral(resourceName: "turrets"))
                    cell(title: "RATE OF FIRE",
                         subtitle: TimeIntervalFormatter.localizedString(from: TimeInterval(duration), precision: .seconds),
                         image: #imageLiteral(resourceName: "rateOfFire"))
                    cell(title: "OPTIMAL RANGE",
                         subtitle: UnitFormatter.localizedString(from: maxRange, unit: .meter, style: .long),
                         image: #imageLiteral(resourceName: "rateOfFire"))
                    cell(title: "FALLOFF",
                         subtitle: UnitFormatter.localizedString(from: falloff, unit: .meter, style: .long),
                         image: #imageLiteral(resourceName: "falloff"))
                }
            }
            return type[SDEAttributeID.speed].map{row(speed: $0.value)}
        }
        
        func missiles() -> some View {
            func row(missile: SDEInvType)  -> some View {
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
                let maxRange = duringAcceleration + fullSpeed;
                
                let interval = duration > 0 ? duration : 1
                let dps = total / interval
                
                
                return Group {
                    NavigationLink(destination: TypeInfo(type: missile)) {
                        cell(title: "MISSILE", subtitle: missile.typeName ?? "", image: missile.uiImage)
                    }
                    TypeInfoDamageCell(damage: Damage(em: em * damageMultiplier,
                                                      thermal: thermal * damageMultiplier,
                                                      kinetic: kinetic * damageMultiplier,
                                                      explosive: explosive * damageMultiplier), percentStyle: false)
                    
                    cell(title: "DAMAGE PER SECOND",
                         subtitle: UnitFormatter.localizedString(from: dps, unit: .none, style: .long),
                         image: #imageLiteral(resourceName: "launchers"))
                    cell(title: "RATE OF FIRE",
                         subtitle: TimeIntervalFormatter.localizedString(from: TimeInterval(duration), precision: .seconds),
                         image: #imageLiteral(resourceName: "rateOfFire"))
                    cell(title: "OPTIMAL RANGE",
                         subtitle: UnitFormatter.localizedString(from: maxRange, unit: .meter, style: .long),
                         image: #imageLiteral(resourceName: "targetingRange"))
                }
            }
            let attribute = type[SDEAttributeID.entityMissileTypeID].map{Int($0.value)}
            let missile = attribute.flatMap{attribute in try? managedObjectContext.from(SDEInvType.self).filter(\SDEInvType.typeID == attribute).first()}
            return missile.map{row(missile: $0)}
        }
        
        func shield() -> some View {
            func capacity() -> String? {
                guard let capacity = type[SDEAttributeID.shieldCapacity]?.value,
                    let rechargeRate = type[SDEAttributeID.shieldRechargeRate]?.value,
                    rechargeRate > 0 && capacity > 0 else {return nil}
                let passive = 10.0 / (rechargeRate / 1000.0) * 0.5 * (1 - 0.5) * capacity
                return UnitFormatter.localizedString(from: passive, unit: .hpPerSecond, style: .long)
            }
            
            func repair() -> String? {
                guard let amount = type[SDEAttributeID.entityShieldBoostAmount]?.value,
                    let duration = type[SDEAttributeID.entityShieldBoostDuration]?.value,
                    duration > 0 && amount > 0 else {return nil}
                let chance = (type[SDEAttributeID.entityShieldBoostDelayChance] ??
                    type[SDEAttributeID.entityShieldBoostDelayChanceSmall] ??
                    type[SDEAttributeID.entityShieldBoostDelayChanceMedium] ??
                    type[SDEAttributeID.entityShieldBoostDelayChanceLarge])?.value ?? 0
                
                let repair = amount / (duration * (1 + chance) / 1000.0)
                return UnitFormatter.localizedString(from: repair, unit: .hpPerSecond, style: .long)
            }
            
            return Group {
                capacity().map{cell(title: "PASSIVE RECHARGE RATE", subtitle: $0, image: #imageLiteral(resourceName: "shieldRecharge"))}
                repair().map{cell(title: "REPAIR RATE", subtitle: $0, image: #imageLiteral(resourceName: "shieldBooster"))}
            }
        }
        
        func armor() -> some View {
            func repair() -> String? {
                guard let amount = type[SDEAttributeID.entityArmorRepairAmount]?.value,
                    let duration = type[SDEAttributeID.entityArmorRepairDuration]?.value,
                    duration > 0 && amount > 0 else {return nil}
                let chance = (type[SDEAttributeID.entityArmorRepairDelayChance] ??
                    type[SDEAttributeID.entityArmorRepairDelayChanceSmall] ??
                    type[SDEAttributeID.entityArmorRepairDelayChanceMedium] ??
                    type[SDEAttributeID.entityArmorRepairDelayChanceLarge])?.value ?? 0
                
                let repair = amount / (duration * (1 + chance) / 1000.0)
                return UnitFormatter.localizedString(from: repair, unit: .hpPerSecond, style: .long)
            }
            
            return repair().map{cell(title: "REPAIR RATE", subtitle: $0, image: #imageLiteral(resourceName: "armorRepairer"))}
        }
        
        return Section(header: Text(sectionTitle.uppercased())) {
            if categoryID == .turrets {
                turrets()
            }
            else if categoryID == .missile {
                missiles()
            }
            else {
                ForEach(section.objects, id: \.objectID) { attribute in
                    self.basicInfo(for: attribute)
                }
                
                if categoryID == .shield {
                    shield()
                }
                else if categoryID == .armor {
                    armor()
                }
            }
        }

    }
    
    private func npcInfo() -> some View {
        var sections = attributes.sections
        _ = sections.partition{$0.objects.first?.attributeType?.attributeCategory?.categoryID != SDEAttributeCategoryID.entityRewards.rawValue}
        
        return ForEach(sections, id: \.name) { section in
            self.npcInfo(for: section)
        }
        
    }
    
    private func activityInfo(for activity: SDEIndActivity) -> some View {
        let products = (activity.products?.allObjects as? [SDEIndProduct])?.filter {$0.productType?.typeName != nil}.sorted {$0.productType!.typeName! < $1.productType!.typeName!}
        
        return Section(header: Text(activity.activity?.activityName?.uppercased() ?? "")) {
            cell(title: "TIME",
                 subtitle: TimeIntervalFormatter.localizedString(from: TimeInterval(activity.time), precision: .seconds),
                 image: #imageLiteral(resourceName: "skillRequirementQueued"))
            ForEach(products ?? [], id: \.objectID) { product in
                NavigationLink(destination: TypeInfo(type: product.productType!)) {
                    self.cell(title: product.productType?.typeName?.uppercased() ?? "",
                              subtitle: "x\(product.quantity) (\(Int(product.probability * 100))%)",
                        image: product.productType?.uiImage)
                }
            }
            if activity.requiredMaterials?.count ?? 0 > 0 {
                NavigationLink(destination: BlueprintActivityMaterials(activity: activity)) {
                    Text("MATERIALS").font(.footnote)
                }
            }
        }
    }

    private func blueprintInfo() -> some View {
        let activities = (type.blueprintType?.activities?.allObjects as? [SDEIndActivity])?.sorted {$0.activity!.activityID < $1.activity!.activityID} ?? []
        return ForEach(activities, id: \.objectID) { activity in
            self.activityInfo(for: activity)
        }
        
    }
}

struct TypeInfo_Previews: PreviewProvider {
    static var previews: some View {
//        let account = Account(token: oAuth2Token, context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        return NavigationView {
            TypeInfo(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!)
                .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
                .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext.newBackgroundContext())
//                .environment(\.account, account)
//                .environment(\.esi, ESI(token: oAuth2Token))
        }
    }
}

