//
//  NPCInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/31/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct NPCInfo: View {
    var type: SDEInvType

    private var attributes: FetchedResultsController<SDEDgmTypeAttribute> {
        let controller = managedObjectContext.from(SDEDgmTypeAttribute.self)
            .filter(/\SDEDgmTypeAttribute.type == type && /\SDEDgmTypeAttribute.attributeType?.published == true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, ascending: true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeID, ascending: true)
            .fetchedResultsController(sectionName: /\SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, cacheName: nil)
        return FetchedResultsController(controller)
    }
    
//    private func cell(title: LocalizedStringKey, subtitle: String?, image: UIImage?) -> some View {
//        HStack {
//            image.map{Icon(Image(uiImage: $0)).cornerRadius(4)}
//            VStack(alignment: .leading) {
//                Text(title)
//                subtitle.map{Text($0).modifier(SecondaryLabelModifier())}
//            }
//        }
//    }
//
    private func section(for section: FetchedResultsController<SDEDgmTypeAttribute>.Section) -> some View {
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

                    TypeInfoAttributeCell(title: Text("Damage per Second"),
                                          subtitle: Text(UnitFormatter.localizedString(from: dps, unit: .none, style: .long)),
                                          image: Image("turrets"))
                    
                    TypeInfoAttributeCell(title: Text("Rate of Fire"),
                                          subtitle: Text(TimeIntervalFormatter.localizedString(from: TimeInterval(duration), precision: .seconds)),
                                          image: Image("rateOfFire"))

                    TypeInfoAttributeCell(title: Text("Optimal Range"),
                                          subtitle: Text(UnitFormatter.localizedString(from: maxRange, unit: .meter, style: .long)),
                                          image: Image("targetingRange"))

                    TypeInfoAttributeCell(title: Text("Falloff"),
                                          subtitle: Text(UnitFormatter.localizedString(from: falloff, unit: .meter, style: .long)),
                                          image: Image("falloff"))
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
                        TypeInfoAttributeCell(title: Text("Missile"),
                                              subtitle: Text(missile.typeName ?? ""),
                                              image: missile.image,
                                              targetType: missile)
                    }
                    TypeInfoDamageCell(damage: Damage(em: em * damageMultiplier,
                                                      thermal: thermal * damageMultiplier,
                                                      kinetic: kinetic * damageMultiplier,
                                                      explosive: explosive * damageMultiplier), percentStyle: false)
                    
                    TypeInfoAttributeCell(title: Text("Damage per Second"),
                                          subtitle: Text(UnitFormatter.localizedString(from: dps, unit: .none, style: .long)),
                                          image: Image("turrets"))
                    
                    TypeInfoAttributeCell(title: Text("Rate of Fire"),
                                          subtitle: Text(TimeIntervalFormatter.localizedString(from: TimeInterval(duration), precision: .seconds)),
                                          image: Image("rateOfFire"))

                    TypeInfoAttributeCell(title: Text("Optimal Range"),
                                          subtitle: Text(UnitFormatter.localizedString(from: maxRange, unit: .meter, style: .long)),
                                          image: Image("targetingRange"))
                }
            }
            let attribute = type[SDEAttributeID.entityMissileTypeID].map{Int32($0.value)}
            let missile = attribute.flatMap{attribute in try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == attribute).first()}
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
                capacity().map{
                    TypeInfoAttributeCell(title: Text("Passive Recharge Rate"),
                                          subtitle: Text($0),
                                          image: Image("shieldRecharge"))
                }
                repair().map{
                    TypeInfoAttributeCell(title: Text("Repair Rate"),
                                          subtitle: Text($0),
                                          image: Image("shieldBooster"))
                }
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
            
            return repair().map{
                TypeInfoAttributeCell(title: Text("Repair Rate"),
                                      subtitle: Text($0),
                                      image: Image("armorRepairer"))
            }
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
                    AttributeInfo(attribute: attribute, attributeValues: nil)
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

    @Environment(\.managedObjectContext) var managedObjectContext

    var body: some View {
        var sections = attributes.sections
        _ = sections.partition{$0.objects.first?.attributeType?.attributeCategory?.categoryID != SDEAttributeCategoryID.entityRewards.rawValue}
        
        return ForEach(sections, id: \.name) { section in
            self.section(for: section)
        }
    }
}

struct NPCInfo_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                NPCInfo(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext
                    .from(SDEInvType.self)
                    .filter((/\SDEInvType.group?.npcGroups).count > 0)
                    .first()!)
            }.listStyle(GroupedListStyle())
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
