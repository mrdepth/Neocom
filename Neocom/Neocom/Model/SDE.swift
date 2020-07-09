//
//  SDE.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/2/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import Expressible
import EVEAPI
import Dgmpp
import SwiftUI

extension SDEInvType {
    subscript(key: SDEAttributeID) -> SDEDgmTypeAttribute? {
        return self[key.rawValue]
    }
    
    subscript(key: Int32) -> SDEDgmTypeAttribute? {
        return (try? managedObjectContext?.from(SDEDgmTypeAttribute.self).filter(/\SDEDgmTypeAttribute.type == self && /\SDEDgmTypeAttribute.attributeType?.attributeID == key).first()) ?? nil
    }

}

public enum SDEAttributeID: Int32, Codable {
    case none = 0
    case charismaBonus = 175
    case intelligenceBonus = 176
    case memoryBonus = 177
    case perceptionBonus = 178
    case willpowerBonus = 179
    case primaryAttribute = 180
    case secondaryAttribute = 181
    case skillTimeConstant = 275
    
    case charisma = 164
    case intelligence = 165
    case memory = 166
    case perception = 167
    case willpower = 168
    
    case implantness = 331
    
    case warpSpeedMultiplier = 600
    case baseWarpSpeed = 1281
    
    case kineticDamageResonance = 109
    case thermalDamageResonance = 110
    case explosiveDamageResonance = 111
    case emDamageResonance = 113
    case armorEmDamageResonance = 267
    case armorExplosiveDamageResonance = 268
    case armorKineticDamageResonance = 269
    case armorThermalDamageResonance = 270
    case shieldEmDamageResonance = 271
    case shieldExplosiveDamageResonance = 272
    case shieldKineticDamageResonance = 273
    case shieldThermalDamageResonance = 274
    
    case passiveShieldThermalDamageResonance = 1425
    case passiveShieldKineticDamageResonance = 1424
    case passiveShieldExplosiveDamageResonance = 1422
    case passiveShieldEmDamageResonance = 1423
    case hullThermalDamageResonance = 977
    case hullKineticDamageResonance = 976
    case hullExplosiveDamageResonance = 975
    case hullEmDamageResonance = 974
    case passiveArmorThermalDamageResonance = 1419
    case passiveArmorKineticDamageResonance = 1420
    case passiveArmorExplosiveDamageResonance = 1421
    case passiveArmorEmDamageResonance = 1418
    
    case emDamage = 114
    case explosiveDamage = 116
    case kineticDamage = 117
    case thermalDamage = 118
    
    case signatureRadius = 552
    
    case missileLaunchDuration = 506
    case entityMissileTypeID = 507
    case maxVelocity = 37
    case speed = 51
    case maxRange = 54
    case falloff = 158
    case trackingSpeed = 160
    case damageMultiplier = 64
    case agility = 70
    case explosionDelay = 281
    case missileDamageMultiplier = 212
    case missileEntityVelocityMultiplier = 645
    case missileEntityFlightTimeMultiplier = 646
    case shieldRechargeRate = 479
    case shieldCapacity = 263
    
    case entityShieldBoostDuration = 636
    case entityShieldBoostAmount = 637
    case entityArmorRepairDuration = 630
    case entityArmorRepairAmount = 631
    
    case entityShieldBoostDelayChance = 639
    case entityShieldBoostDelayChanceSmall = 1006
    case entityShieldBoostDelayChanceMedium = 1007
    case entityShieldBoostDelayChanceLarge = 1008
    case entityArmorRepairDelayChance = 638
    case entityArmorRepairDelayChanceSmall = 1009
    case entityArmorRepairDelayChanceMedium = 1010
    case entityArmorRepairDelayChanceLarge = 1011
}

public enum SDEAttributeCategoryID: Int32 {
    case none = 0
    case fitting = 1
    case shield = 2
    case armor = 3
    case structure = 4
    case requiredSkills = 8
    case null = 9
    case turrets = 29
    case missile = 30
    case entityRewards = 32
}

public enum SDEUnitID: Int32 {
    case none = 0
    case milliseconds = 101
    case inverseAbsolutePercent = 108
    case modifierPercent = 109
    case inversedModifierPercent = 111
    case groupID = 115
    case typeID = 116
    case sizeClass = 117
    case attributeID = 119
    case fittingSlots = 122
    case absolutePercent = 127
    case boolean = 137
    case bonus = 139
}

public enum SDECategoryID: Int32 {
    case ship = 6
    case module = 7
    case charge = 8
    case blueprint = 9
    case skill = 16
    case drone = 18
    case subsystem = 32
    case fighter = 87
    case structure = 65
    case structureModule = 66
    
    case asteroid = 25
    case ancientRelic = 34
    case material = 4
    case planetaryResource = 42
    case reaction = 24
    case entity = 11
}

public enum SDEGroupID: Int32 {
	case effectBeacon = 920
}

public enum SDERegionID: Int32 {
    case theForge = 10000002
    case whSpace = 11000000
    
    static let `default` = SDERegionID.theForge
}

public enum SDEDgmppItemCategoryID: Int32 {
    case none = 0
    case hi
    case med
    case low
    case rig
    case subsystem
    case mode
    case charge
    case drone
    case fighter
    case implant
    case booster
    case ship
    case structure
    case service
    case structureFighter
    case structureRig
    case cargo
}

public enum SDEEffectID: Int32 {
    case missileLaunchingForEntity = 569
}

public enum SDEIndActivityID: Int32 {
    case none = 0
    case manufacturing = 1
    case researchingTechnology = 2
    case researchingTimeEfficiency = 3
    case researchingMaterialEfficiency = 4
    case copying = 5
    case duplicating = 6
    case reverseEngineering = 7
    case invention = 8
    case reactions = 11
}

public enum SDERigSize: Int, CustomStringConvertible {
    case none = 0
    case small = 1
    case medium = 2
    case large = 3
    case xLarge = 4
    
    public var description: String {
        switch self {
        case .none:
            return NSLocalizedString("N/A", comment: "")
        case .small:
            return  NSLocalizedString("Small", comment: "")
        case .medium:
            return  NSLocalizedString("Medium", comment: "")
        case .large:
            return  NSLocalizedString("Large", comment: "")
        case .xLarge:
            return  NSLocalizedString("X-Large", comment: "")
        }
    }
}

extension SDEMapRegion {
    @objc public var securityClassDisplayName: String {
        switch securityClass {
        case 1:
            return NSLocalizedString("High-Sec", comment: "")
        case 0.5:
            return NSLocalizedString("Low-Sec", comment: "")
        case 0:
            return NSLocalizedString("Null-Sec", comment: "")
        default:
            return NSLocalizedString("WH-Space", comment: "")
        }
    }
}

var damageResonanceAttributes: [[DamageType: SDEAttributeID]] = [
    [.em: .emDamageResonance,
     .thermal: .thermalDamageResonance,
     .kinetic: .kineticDamageResonance,
     .explosive: .explosiveDamageResonance],
    
    [.em: .armorEmDamageResonance,
     .thermal: .armorThermalDamageResonance,
     .kinetic: .armorKineticDamageResonance,
     .explosive: .armorExplosiveDamageResonance],
    
    [.em: .shieldEmDamageResonance,
     .thermal: .shieldThermalDamageResonance,
     .kinetic: .shieldKineticDamageResonance,
     .explosive: .shieldExplosiveDamageResonance],

    [.em: .hullEmDamageResonance,
     .thermal: .hullThermalDamageResonance,
     .kinetic: .hullKineticDamageResonance,
     .explosive: .hullExplosiveDamageResonance],

    [.em: .passiveArmorEmDamageResonance,
     .thermal: .passiveArmorThermalDamageResonance,
     .kinetic: .passiveArmorKineticDamageResonance,
     .explosive: .passiveArmorExplosiveDamageResonance],

    [.em: .passiveShieldEmDamageResonance,
     .thermal: .passiveShieldThermalDamageResonance,
     .kinetic: .passiveShieldKineticDamageResonance,
     .explosive: .passiveShieldExplosiveDamageResonance],
]

var damageAttributes: [[DamageType: SDEAttributeID]] = [
    [.em: .emDamage,
     .thermal: .thermalDamage,
     .kinetic: .kineticDamage,
     .explosive: .explosiveDamage]
]

enum ItemFlag: Int32, Hashable {
    case hiSlot
    case medSlot
    case lowSlot
    case rigSlot
    case subsystemSlot
    case service
    case drone
    case cargo
    case hangar
    case skill
    case implant
    
    init?(flag: ESI.LocationFlag) {
        switch flag {
        case .hiSlot0, .hiSlot1, .hiSlot2, .hiSlot3, .hiSlot4, .hiSlot5, .hiSlot6, .hiSlot7:
            self = .hiSlot
        case .medSlot0, .medSlot1, .medSlot2, .medSlot3, .medSlot4, .medSlot5, .medSlot6, .medSlot7:
            self = .medSlot
        case .loSlot0, .loSlot1, .loSlot2, .loSlot3, .loSlot4, .loSlot5, .loSlot6, .loSlot7:
            self = .lowSlot
        case .rigSlot0, .rigSlot1, .rigSlot2, .rigSlot3, .rigSlot4, .rigSlot5, .rigSlot6, .rigSlot7:
            self = .rigSlot
        case .subSystemSlot0, .subSystemSlot1, .subSystemSlot2, .subSystemSlot3, .subSystemSlot4, .subSystemSlot5, .subSystemSlot6, .subSystemSlot7:
            self = .subsystemSlot
        case .droneBay, .fighterBay, .fighterTube0, .fighterTube1, .fighterTube2, .fighterTube3, .fighterTube4:
            self = .drone
        case .hangar, .fleetHangar, .hangarAll, .shipHangar, .specializedLargeShipHold, .specializedIndustrialShipHold, .specializedMediumShipHold, .specializedShipHold, .specializedSmallShipHold :
            self = .hangar
        case .cargo, .corpseBay, .specializedAmmoHold, .specializedCommandCenterHold, .specializedFuelBay, .specializedGasHold, .specializedMaterialBay, .specializedMineralHold, .specializedOreHold, .specializedPlanetaryCommoditiesHold, .specializedSalvageHold:
            self = .cargo
        case .skill:
            self = .skill
        case .implant:
            self = .implant
        default:
            return nil
        }
    }
    
    init?(flag: ESI.CorporationLocationFlag) {
        guard let flag = ESI.LocationFlag(rawValue: flag.rawValue) else {return nil}
        self.init(flag: flag)
    }
    
    var image: Image? {
        switch self {
        case .hiSlot:
            return DGMModule.Slot.hi.image
        case .medSlot:
            return DGMModule.Slot.med.image
        case .lowSlot:
            return DGMModule.Slot.low.image
        case .rigSlot:
            return DGMModule.Slot.rig.image
        case .subsystemSlot:
            return DGMModule.Slot.subsystem.image
        case .service:
            return DGMModule.Slot.service.image
        case .drone:
            return Image("drone")
        case .cargo:
            return Image("cargoBay")
        case .hangar:
            return Image("ships")
        case .implant:
            return Image("implant")
        case .skill:
            return Image("skills")
        }
    }
    
    var title: String? {
        switch self {
        case .hiSlot:
            return DGMModule.Slot.hi.title
        case .medSlot:
            return DGMModule.Slot.med.title
        case .lowSlot:
            return DGMModule.Slot.low.title
        case .rigSlot:
            return DGMModule.Slot.rig.title
        case .subsystemSlot:
            return DGMModule.Slot.subsystem.title
        case .service:
            return DGMModule.Slot.service.title
        case .drone:
            return NSLocalizedString("Drones", comment: "")
        case .cargo:
            return NSLocalizedString("Cargo", comment: "")
        case .hangar:
            return NSLocalizedString("Hangar", comment: "")
        case .implant:
            return NSLocalizedString("Implant", comment: "")
        case .skill:
            return NSLocalizedString("Skill", comment: "")
        }
    }
    
    var tableSectionHeader: some View {
        HStack {
            image.map{Icon($0, size: .small)}
            Text(title?.uppercased() ?? "")
        }
    }
}



extension SDEInvCategory {
    
    var uiImage: UIImage {
        icon?.image?.image ?? (try? managedObjectContext?.fetch(SDEEveIcon.named(.defaultCategory)).first?.image?.image) ?? UIImage()
    }
    
    var image: Image {
        Image(uiImage: uiImage)
    }
}

extension SDEInvGroup {
    var uiImage: UIImage {
        icon?.image?.image ??
        (try? managedObjectContext?.fetch(SDEEveIcon.named(.defaultGroup)).first?.image?.image) ??
        UIImage()
    }
    
    var image: Image {
        Image(uiImage: uiImage)
    }
}

extension SDEInvMarketGroup {
    var uiImage: UIImage {
        icon?.image?.image ??
            (try? managedObjectContext?.fetch(SDEEveIcon.named(.defaultGroup)).first?.image?.image) ??
            UIImage()
    }
    
    var image: Image {
        Image(uiImage: uiImage)
    }

}

extension SDENpcGroup {
    var uiImage: UIImage {
        icon?.image?.image ??
            (try? managedObjectContext?.fetch(SDEEveIcon.named(.defaultGroup)).first?.image?.image) ??
            UIImage()
    }
    
    var image: Image {
        Image(uiImage: uiImage)
    }

}

extension SDEInvType {
    var uiImage: UIImage {
        icon?.image?.image ??
            (try? managedObjectContext?.fetch(SDEEveIcon.named(.defaultType)).first?.image?.image) ??
            UIImage()
    }
    
    var image: Image {
        Image(uiImage: uiImage)
    }

}

extension SDEEveIcon {
    class func named(_ name: Name) -> NSFetchRequest<SDEEveIcon> {
        let request = NSFetchRequest<SDEEveIcon>(entityName: "EveIcon")
        request.predicate = (/\SDEEveIcon.iconFile == name.name).predicate(for: .`self`)
        request.fetchLimit = 1
        return request
    }
    
    enum Name {
        case defaultCategory
        case defaultGroup
        case defaultType
        case mastery(Int?)
        case custom(String)
        
        var name: String {
            switch self {
            case .defaultCategory, .defaultGroup:
                return "38_16_174"
            case .defaultType:
                return "7_64_15"
            case let .mastery(level):
                guard let level = level, (0...4).contains(level) else {return "79_64_1"}
                return "79_64_\(level + 2)"
            case let .custom(name):
                return name
            }
        }
    }
}

extension SDEDgmppItemGroup {
    var uiImage: UIImage {
        icon?.image?.image ??
        (try? managedObjectContext?.fetch(SDEEveIcon.named(.defaultGroup)).first?.image?.image) ??
        UIImage()
    }
    
    var image: Image {
        Image(uiImage: uiImage)
    }
    
    class func rootGroup(categoryID: SDEDgmppItemCategoryID, subcategory: Int? = nil, race: SDEChrRace? = nil) -> NSFetchRequest<SDEDgmppItemGroup> {
        var predicate = /\SDEDgmppItemGroup.parentGroup == nil && /\SDEDgmppItemGroup.category?.category == categoryID.rawValue
        
        if let subcategory = subcategory {
            predicate = predicate && /\SDEDgmppItemGroup.category?.subcategory == Int32(subcategory)
        }
        
        if let race = race {
            predicate = predicate && /\SDEDgmppItemGroup.category?.race == race
        }

        if let subcategory = subcategory {
            predicate = predicate && /\SDEDgmppItemGroup.category?.subcategory == Int32(subcategory)
        }
        
        if let race = race {
            predicate = predicate && /\SDEDgmppItemGroup.category?.race == race
        }
        
        let request = NSFetchRequest<SDEDgmppItemGroup>(entityName: "DgmppItemGroup")
        request.predicate = predicate.predicate(for: .self)
        request.fetchLimit = 1
        return request
    }
    
    class func rootGroup(slot: DGMModule.Slot, subcategory: Int? = nil, race: SDEChrRace? = nil, structure: Bool) -> NSFetchRequest<SDEDgmppItemGroup> {
        let categoryID: SDEDgmppItemCategoryID
        switch slot {
        case .hi:
            categoryID = .hi
        case .med:
            categoryID = .med
        case .low:
            categoryID = .low
        case .rig:
            categoryID = structure ? .structureRig : .rig
        case .subsystem:
            categoryID = .subsystem
        case .mode:
            categoryID = .mode
        case .service:
            categoryID = .service
        case .starbaseStructure:
            categoryID = .structure
        default:
            categoryID = .none
        }
        return rootGroup(categoryID: categoryID, subcategory: subcategory, race: race)
    }
}

extension SDEInvType: Identifiable {
    public var id: NSManagedObjectID {
        return objectID
    }
}
extension SDEDgmppItemCategory: Identifiable {
    public var id: NSManagedObjectID {
        return objectID
    }
}
extension SDEDgmppItemGroup: Identifiable {
    public var id: NSManagedObjectID {
        return objectID
    }
}

extension DamagePattern: Identifiable {
    public var id: NSManagedObjectID {
        return objectID
    }
    
    var damageVector: DGMDamageVector {
        get {
            DGMDamageVector(em: DGMHP(em), thermal: DGMHP(thermal), kinetic: DGMHP(kinetic), explosive: DGMHP(explosive)).normalized
        }
        set {
            let vector = newValue.normalized
            em = Float(vector.em)
            thermal = Float(vector.thermal)
            kinetic = Float(vector.kinetic)
            explosive = Float(vector.explosive)
        }
    }
}

extension SDEInvType {
    var npcDPS: DGMDamageVector? {
        func getAttributes(from type: SDEInvType) -> [Int32: Double] {
            let pairs = (type.attributes?.allObjects as? [SDEDgmTypeAttribute])?.map{($0.attributeType!.attributeID, $0.value)} ?? []
            return Dictionary(pairs) {a, _ in a}
        }
        
        let attributes = getAttributes(from: self)

        let turrets: DGMDamageVector = {
            let damage = DGMDamageVector(em: attributes[SDEAttributeID.emDamage.rawValue] ?? 0,
                                         thermal: attributes[SDEAttributeID.thermalDamage.rawValue] ?? 0,
                                         kinetic: attributes[SDEAttributeID.kineticDamage.rawValue] ?? 0,
                                         explosive: attributes[SDEAttributeID.explosiveDamage.rawValue] ?? 0)
            
            let multiplier = attributes[SDEAttributeID.damageMultiplier.rawValue] ?? 1
            let rof = (attributes[SDEAttributeID.speed.rawValue] ?? 1000) / 1000
            return rof > 0 ? damage * (multiplier / rof) : .zero
        }()
        
        let launchers: DGMDamageVector = {
            guard let missileID = attributes[SDEAttributeID.entityMissileTypeID.rawValue], let missile = try? managedObjectContext?.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(missileID)).first() else {return .zero}
            
            let missileAttributes = getAttributes(from: missile)
            let damage = DGMDamageVector(em: missileAttributes[SDEAttributeID.emDamage.rawValue] ?? 0,
                                         thermal: missileAttributes[SDEAttributeID.thermalDamage.rawValue] ?? 0,
                                         kinetic: missileAttributes[SDEAttributeID.kineticDamage.rawValue] ?? 0,
                                         explosive: missileAttributes[SDEAttributeID.explosiveDamage.rawValue] ?? 0)
            
            let multiplier = attributes[SDEAttributeID.missileDamageMultiplier.rawValue] ?? 1
            let rof = (attributes[SDEAttributeID.missileLaunchDuration.rawValue] ?? 1000) / 1000
            return rof > 0 ? damage * (multiplier / rof) : .zero
        }()
        let dps = turrets + launchers
        return dps.total > 0 ? dps : nil
    }
}

extension SDEWhType {
    @objc var targetSystemClassDisplayName: String? {
        switch targetSystemClass {
        case 0:
            return NSLocalizedString("Exit WH", comment: "")
        case 1...6:
            return String(format: NSLocalizedString("W-Space Class %d", comment: ""), targetSystemClass)
        case 7:
            return NSLocalizedString("High-Sec", comment: "")
        case 8:
            return NSLocalizedString("Low-Sec", comment: "")
        case 9:
            return NSLocalizedString("0.0 System", comment: "")
        case 12:
            return NSLocalizedString("Thera", comment: "")
        case 13:
            return NSLocalizedString("W-Frig", comment: "")
        case 14:
            return NSLocalizedString("Sentinel", comment: "")
        case 15:
            return NSLocalizedString("Barbican", comment: "")
        case 16:
            return NSLocalizedString("Vidette", comment: "")
        case 17:
            return NSLocalizedString("Conflux", comment: "")
        case 18:
            return NSLocalizedString("Redoubt", comment: "")
        default:
            return String(format: NSLocalizedString("Unknown Class %d", comment: ""), targetSystemClass)
        }
    }
}
