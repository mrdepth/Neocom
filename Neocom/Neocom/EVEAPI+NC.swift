//
//  EVEAPI+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import SafariServices

extension ESI.Calendar.Summary.Response {
	var title: String {
		switch self {
		case .accepted:
			return NSLocalizedString("Accepted", comment: "")
		case .declined:
			return NSLocalizedString("Declined", comment: "")
		case .notResponded:
			return NSLocalizedString("Not Responded", comment: "")
		case .tentative:
			return NSLocalizedString("Tentative", comment: "")
		}
	}
}

extension ESI.Calendar.Response.Response {
	var title: String {
		switch self {
		case .accepted:
			return NSLocalizedString("Accepted", comment: "")
		case .declined:
			return NSLocalizedString("Declined", comment: "")
		case .tentative:
			return NSLocalizedString("Tentative", comment: "")
		}
	}
}

extension ESI.Contracts.Contract.ContractType {
	var title: String {
		switch self {
		case .auction:
			return NSLocalizedString("Auction", comment: "")
		case .courier:
			return NSLocalizedString("Courier", comment: "")
		case .itemExchange:
			return NSLocalizedString("Item Exchange", comment: "")
		case .loan:
			return NSLocalizedString("Loan", comment: "")
		case .unknown:
			return NSLocalizedString("Unknown", comment: "")
		}
	}
}

extension ESI.Contracts.Contract.Availability {
	var title: String {
		switch self {
		case .alliance:
			return NSLocalizedString("Alliance", comment: "")
		case .corporation:
			return NSLocalizedString("Corporation", comment: "")
		case .personal:
			return NSLocalizedString("Personal", comment: "")
		case .public:
			return NSLocalizedString("Public", comment: "")
		}
	}
}

extension ESI.Contracts.Contract.Status {
	var title: String {
		switch self {
		case .outstanding:
			return NSLocalizedString("Outstanding", comment: "")
		case .inProgress:
			return NSLocalizedString("In Progress", comment: "")
		case .cancelled:
			return NSLocalizedString("Cancelled", comment: "")
		case .deleted:
			return NSLocalizedString("Deleted", comment: "")
		case .failed:
			return NSLocalizedString("Failed", comment: "")
		case .finished, .finishedContractor, .finishedIssuer:
			return NSLocalizedString("Finished", comment: "")
		case .rejected:
			return NSLocalizedString("Rejected", comment: "")
		case .reversed:
			return NSLocalizedString("Reversed", comment: "")
		}
	}

}

extension ESI.Contracts.Contract {
	var currentStatus: ESI.Contracts.Contract.Status {
		switch status {
		case .outstanding, .inProgress:
			return dateExpired < Date() ? .finished : status
		default:
			return status
		}
	}
	var isOpen: Bool {
		return dateExpired > Date() && (status == .outstanding || status == .inProgress)
	}
}

extension ESI.Industry.Job {
	var currentStatus: ESI.Industry.JobStatus {
		switch status {
		case .active:
			return endDate < Date() ? .ready : status
		default:
			return status
		}
	}
}


extension ESI.Incursions.Incursion.State {
	var title: String {
		switch self {
		case .established:
			return NSLocalizedString("Established", comment: "")
		case .mobilizing:
			return NSLocalizedString("Mobilizing", comment: "")
		case .withdrawing:
			return NSLocalizedString("Withdrawing", comment: "")
		}
	}
	
}

extension ESI.Assets.Asset.Flag {
	init?(_ value: Int) {
		let result: ESI.Assets.Asset.Flag?
		switch value {
		case 0:
			result = ESI.Assets.Asset.Flag(rawValue: "None")
		case 1:
			result = ESI.Assets.Asset.Flag(rawValue: "Wallet")
		case 2:
			result = ESI.Assets.Asset.Flag(rawValue: "Factory")
		case 3:
			result = ESI.Assets.Asset.Flag(rawValue: "Wardrobe")
		case 4:
			result = ESI.Assets.Asset.Flag(rawValue: "Hangar")
		case 5:
			result = ESI.Assets.Asset.Flag(rawValue: "Cargo")
		case 6:
			result = ESI.Assets.Asset.Flag(rawValue: "Briefcase")
		case 7:
			result = ESI.Assets.Asset.Flag(rawValue: "Skill")
		case 8:
			result = ESI.Assets.Asset.Flag(rawValue: "Reward")
		case 9:
			result = ESI.Assets.Asset.Flag(rawValue: "Connected")
		case 10:
			result = ESI.Assets.Asset.Flag(rawValue: "Disconnected")
		case 11:
			result = ESI.Assets.Asset.Flag(rawValue: "LoSlot0")
		case 12:
			result = ESI.Assets.Asset.Flag(rawValue: "LoSlot1")
		case 13:
			result = ESI.Assets.Asset.Flag(rawValue: "LoSlot2")
		case 14:
			result = ESI.Assets.Asset.Flag(rawValue: "LoSlot3")
		case 15:
			result = ESI.Assets.Asset.Flag(rawValue: "LoSlot4")
		case 16:
			result = ESI.Assets.Asset.Flag(rawValue: "LoSlot5")
		case 17:
			result = ESI.Assets.Asset.Flag(rawValue: "LoSlot6")
		case 18:
			result = ESI.Assets.Asset.Flag(rawValue: "LoSlot7")
		case 19:
			result = ESI.Assets.Asset.Flag(rawValue: "MedSlot0")
		case 20:
			result = ESI.Assets.Asset.Flag(rawValue: "MedSlot1")
		case 21:
			result = ESI.Assets.Asset.Flag(rawValue: "MedSlot2")
		case 22:
			result = ESI.Assets.Asset.Flag(rawValue: "MedSlot3")
		case 23:
			result = ESI.Assets.Asset.Flag(rawValue: "MedSlot4")
		case 24:
			result = ESI.Assets.Asset.Flag(rawValue: "MedSlot5")
		case 25:
			result = ESI.Assets.Asset.Flag(rawValue: "MedSlot6")
		case 26:
			result = ESI.Assets.Asset.Flag(rawValue: "MedSlot7")
		case 27:
			result = ESI.Assets.Asset.Flag(rawValue: "HiSlot0")
		case 28:
			result = ESI.Assets.Asset.Flag(rawValue: "HiSlot1")
		case 29:
			result = ESI.Assets.Asset.Flag(rawValue: "HiSlot2")
		case 30:
			result = ESI.Assets.Asset.Flag(rawValue: "HiSlot3")
		case 31:
			result = ESI.Assets.Asset.Flag(rawValue: "HiSlot4")
		case 32:
			result = ESI.Assets.Asset.Flag(rawValue: "HiSlot5")
		case 33:
			result = ESI.Assets.Asset.Flag(rawValue: "HiSlot6")
		case 34:
			result = ESI.Assets.Asset.Flag(rawValue: "HiSlot7")
		case 35:
			result = ESI.Assets.Asset.Flag(rawValue: "Fixed Slot")
		case 36:
			result = ESI.Assets.Asset.Flag(rawValue: "AssetSafety")
		case 40:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot1")
		case 41:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot2")
		case 42:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot3")
		case 43:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot4")
		case 44:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot5")
		case 45:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot6")
		case 46:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot7")
		case 47:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot8")
		case 48:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot9")
		case 49:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot10")
		case 50:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot11")
		case 51:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot12")
		case 52:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot13")
		case 53:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot14")
		case 54:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot15")
		case 55:
			result = ESI.Assets.Asset.Flag(rawValue: "PromenadeSlot16")
		case 56:
			result = ESI.Assets.Asset.Flag(rawValue: "Capsule")
		case 57:
			result = ESI.Assets.Asset.Flag(rawValue: "Pilot")
		case 58:
			result = ESI.Assets.Asset.Flag(rawValue: "Passenger")
		case 59:
			result = ESI.Assets.Asset.Flag(rawValue: "Boarding Gate")
		case 60:
			result = ESI.Assets.Asset.Flag(rawValue: "Crew")
		case 61:
			result = ESI.Assets.Asset.Flag(rawValue: "Skill In Training")
		case 62:
			result = ESI.Assets.Asset.Flag(rawValue: "CorpMarket")
		case 63:
			result = ESI.Assets.Asset.Flag(rawValue: "Locked")
		case 64:
			result = ESI.Assets.Asset.Flag(rawValue: "Unlocked")
		case 70:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 1")
		case 71:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 2")
		case 72:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 3")
		case 73:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 4")
		case 74:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 5")
		case 75:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 6")
		case 76:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 7")
		case 77:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 8")
		case 78:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 9")
		case 79:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 10")
		case 80:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 11")
		case 81:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 12")
		case 82:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 13")
		case 83:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 14")
		case 84:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 15")
		case 85:
			result = ESI.Assets.Asset.Flag(rawValue: "Office Slot 16")
		case 86:
			result = ESI.Assets.Asset.Flag(rawValue: "Bonus")
		case 87:
			result = ESI.Assets.Asset.Flag(rawValue: "DroneBay")
		case 88:
			result = ESI.Assets.Asset.Flag(rawValue: "Booster")
		case 89:
			result = ESI.Assets.Asset.Flag(rawValue: "Implant")
		case 90:
			result = ESI.Assets.Asset.Flag(rawValue: "ShipHangar")
		case 91:
			result = ESI.Assets.Asset.Flag(rawValue: "ShipOffline")
		case 92:
			result = ESI.Assets.Asset.Flag(rawValue: "RigSlot0")
		case 93:
			result = ESI.Assets.Asset.Flag(rawValue: "RigSlot1")
		case 94:
			result = ESI.Assets.Asset.Flag(rawValue: "RigSlot2")
		case 95:
			result = ESI.Assets.Asset.Flag(rawValue: "RigSlot3")
		case 96:
			result = ESI.Assets.Asset.Flag(rawValue: "RigSlot4")
		case 97:
			result = ESI.Assets.Asset.Flag(rawValue: "RigSlot5")
		case 98:
			result = ESI.Assets.Asset.Flag(rawValue: "RigSlot6")
		case 99:
			result = ESI.Assets.Asset.Flag(rawValue: "RigSlot7")
		case 100:
			result = ESI.Assets.Asset.Flag(rawValue: "Factory Operation")
		case 115:
			result = ESI.Assets.Asset.Flag(rawValue: "CorpSAG1")
		case 116:
			result = ESI.Assets.Asset.Flag(rawValue: "CorpSAG2")
		case 117:
			result = ESI.Assets.Asset.Flag(rawValue: "CorpSAG3")
		case 118:
			result = ESI.Assets.Asset.Flag(rawValue: "CorpSAG4")
		case 119:
			result = ESI.Assets.Asset.Flag(rawValue: "CorpSAG5")
		case 120:
			result = ESI.Assets.Asset.Flag(rawValue: "CorpSAG6")
		case 121:
			result = ESI.Assets.Asset.Flag(rawValue: "CorpSAG7")
		case 122:
			result = ESI.Assets.Asset.Flag(rawValue: "SecondaryStorage")
		case 123:
			result = ESI.Assets.Asset.Flag(rawValue: "CaptainsQuarters")
		case 124:
			result = ESI.Assets.Asset.Flag(rawValue: "Wis Promenade")
		case 125:
			result = ESI.Assets.Asset.Flag(rawValue: "SubSystem0")
		case 126:
			result = ESI.Assets.Asset.Flag(rawValue: "SubSystem1")
		case 127:
			result = ESI.Assets.Asset.Flag(rawValue: "SubSystem2")
		case 128:
			result = ESI.Assets.Asset.Flag(rawValue: "SubSystem3")
		case 129:
			result = ESI.Assets.Asset.Flag(rawValue: "SubSystem4")
		case 130:
			result = ESI.Assets.Asset.Flag(rawValue: "SubSystem5")
		case 131:
			result = ESI.Assets.Asset.Flag(rawValue: "SubSystem6")
		case 132:
			result = ESI.Assets.Asset.Flag(rawValue: "SubSystem7")
		case 133:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedFuelBay")
		case 134:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedOreHold")
		case 135:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedGasHold")
		case 136:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedMineralHold")
		case 137:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedSalvageHold")
		case 138:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedShipHold")
		case 139:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedSmallShipHold")
		case 140:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedMediumShipHold")
		case 141:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedLargeShipHold")
		case 142:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedIndustrialShipHold")
		case 143:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedAmmoHold")
		case 144:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureActive")
		case 145:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureInactive")
		case 146:
			result = ESI.Assets.Asset.Flag(rawValue: "JunkyardReprocessed")
		case 147:
			result = ESI.Assets.Asset.Flag(rawValue: "JunkyardTrashed")
		case 148:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedCommandCenterHold")
		case 149:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedPlanetaryCommoditiesHold")
		case 150:
			result = ESI.Assets.Asset.Flag(rawValue: "PlanetSurface")
		case 151:
			result = ESI.Assets.Asset.Flag(rawValue: "SpecializedMaterialBay")
		case 152:
			result = ESI.Assets.Asset.Flag(rawValue: "DustCharacterDatabank")
		case 153:
			result = ESI.Assets.Asset.Flag(rawValue: "DustCharacterBattle")
		case 154:
			result = ESI.Assets.Asset.Flag(rawValue: "QuafeBay")
		case 155:
			result = ESI.Assets.Asset.Flag(rawValue: "FleetHangar")
		case 156:
			result = ESI.Assets.Asset.Flag(rawValue: "HiddenModifiers")
		case 157:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureOffline")
		case 158:
			result = ESI.Assets.Asset.Flag(rawValue: "FighterBay")
		case 159:
			result = ESI.Assets.Asset.Flag(rawValue: "FighterTube0")
		case 160:
			result = ESI.Assets.Asset.Flag(rawValue: "FighterTube1")
		case 161:
			result = ESI.Assets.Asset.Flag(rawValue: "FighterTube2")
		case 162:
			result = ESI.Assets.Asset.Flag(rawValue: "FighterTube3")
		case 163:
			result = ESI.Assets.Asset.Flag(rawValue: "FighterTube4")
		case 164:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureServiceSlot0")
		case 165:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureServiceSlot1")
		case 166:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureServiceSlot2")
		case 167:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureServiceSlot3")
		case 168:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureServiceSlot4")
		case 169:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureServiceSlot5")
		case 170:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureServiceSlot6")
		case 171:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureServiceSlot7")
		case 172:
			result = ESI.Assets.Asset.Flag(rawValue: "StructureFuel")
		case 173:
			result = ESI.Assets.Asset.Flag(rawValue: "Deliveries")
		default:
			result = nil
		}
		if let res = result {
			self = res
		}
		else {
			return nil
		}
	}
	
	var intValue: Int {
		switch self {
		case .wardrobe:
			return 3
		case .hangar:
			return 4
		case .cargo:
			return 5
		case .loSlot0:
			return 11
		case .loSlot1:
			return 12
		case .loSlot2:
			return 13
		case .loSlot3:
			return 14
		case .loSlot4:
			return 15
		case .loSlot5:
			return 16
		case .loSlot6:
			return 17
		case .loSlot7:
			return 18
		case .medSlot0:
			return 19
		case .medSlot1:
			return 20
		case .medSlot2:
			return 21
		case .medSlot3:
			return 22
		case .medSlot4:
			return 23
		case .medSlot5:
			return 24
		case .medSlot6:
			return 25
		case .medSlot7:
			return 26
		case .hiSlot0:
			return 27
		case .hiSlot1:
			return 28
		case .hiSlot2:
			return 29
		case .hiSlot3:
			return 30
		case .hiSlot4:
			return 31
		case .hiSlot5:
			return 32
		case .hiSlot6:
			return 33
		case .hiSlot7:
			return 34
		case .assetSafety:
			return 36
		case .locked:
			return 63
		case .unlocked:
			return 64
		case .droneBay:
			return 87
		case .implant:
			return 89
		case .shipHangar:
			return 90
		case .rigSlot0:
			return 92
		case .rigSlot1:
			return 93
		case .rigSlot2:
			return 94
		case .rigSlot3:
			return 95
		case .rigSlot4:
			return 96
		case .rigSlot5:
			return 97
		case .rigSlot6:
			return 98
		case .rigSlot7:
			return 99
		case .subSystemSlot0:
			return 125
		case .subSystemSlot1:
			return 126
		case .subSystemSlot2:
			return 127
		case .subSystemSlot3:
			return 128
		case .subSystemSlot4:
			return 129
		case .subSystemSlot5:
			return 130
		case .subSystemSlot6:
			return 131
		case .subSystemSlot7:
			return 132
		case .specializedFuelBay:
			return 133
		case .specializedOreHold:
			return 134
		case .specializedGasHold:
			return 135
		case .specializedMineralHold:
			return 136
		case .specializedSalvageHold:
			return 137
		case .specializedShipHold:
			return 138
		case .specializedSmallShipHold:
			return 139
		case .specializedMediumShipHold:
			return 140
		case .specializedLargeShipHold:
			return 141
		case .specializedIndustrialShipHold:
			return 142
		case .specializedAmmoHold:
			return 143
		case .specializedCommandCenterHold:
			return 148
		case .specializedPlanetaryCommoditiesHold:
			return 149
		case .specializedMaterialBay:
			return 151
		case .quafeBay:
			return 154
		case .fleetHangar:
			return 155
		case .hiddenModifiers:
			return 156
		case .fighterBay:
			return 158
		case .fighterTube0:
			return 159
		case .fighterTube1:
			return 160
		case .fighterTube2:
			return 161
		case .fighterTube3:
			return 162
		case .fighterTube4:
			return 163
		case .structureServiceSlot0:
			return 164
		case .structureServiceSlot1:
			return 165
		case .structureServiceSlot2:
			return 166
		case .structureServiceSlot3:
			return 167
		case .structureServiceSlot4:
			return 168
		case .structureServiceSlot5:
			return 169
		case .structureServiceSlot6:
			return 169
		case .structureServiceSlot7:
			return 171
		case .structureFuel:
			return 172
		case .deliveries:
			return 173
		case .autoFit, .corpseBay, .hangarAll, .subSystemBay, .skill:
			return 0
		}
	}
}

protocol NCAttacker {
	
	var characterID: Int? {get}
	var corporationID: Int? {get}
	var allianceID: Int? {get}
	var factionID: Int? {get}
	var securityStatus: Float {get}
	var damageDone: Int {get}
	var finalBlow: Bool {get}
	var shipTypeID: Int? {get}
	var weaponTypeID: Int? {get}
}

protocol NCVictim {
	var characterID: Int? {get}
	var corporationID: Int? {get}
	var allianceID: Int? {get}
	var factionID: Int? {get}
	var damageTaken: Int {get}
	var shipTypeID: Int {get}
}

protocol NCItem {
	var flag: Int {get}
	var itemTypeID: Int {get}
	var quantityDestroyed: Int64? {get}
	var quantityDropped: Int64? {get}
	var singleton: Int {get}
	
	func getItems() -> [NCItem]?
}

protocol NCKillmail {
	func getAttackers() -> [NCAttacker]
	var killmailID: Int {get}
	var killmailTime: Date {get}
//	var moonID: Int? {get}
	var solarSystemID: Int {get}
	func getVictim() -> NCVictim
	func getItems() -> [NCItem]?
}

extension ESI.Killmails.Killmail.Victim: NCVictim {
}

extension ZKillboard.Killmail.Victim: NCVictim {
}

extension ESI.Killmails.Killmail.Attacker: NCAttacker {
}

extension ZKillboard.Killmail.Attacker: NCAttacker {
}

extension ESI.Killmails.Killmail.Victim.Item: NCItem {
	func getItems() -> [NCItem]? {
		return items
	}
}

extension ESI.Killmails.Killmail.Victim.Item.Item: NCItem {
	func getItems() -> [NCItem]? {
		return nil
	}
}

extension ZKillboard.Killmail.Item: NCItem {
	func getItems() -> [NCItem]? {
		return nil
	}
}

extension ESI.Killmails.Killmail: NCKillmail {
	func getAttackers() -> [NCAttacker] {
		return attackers
	}
	
	func getVictim() -> NCVictim {
		return victim
	}
	
	func getItems() -> [NCItem]? {
		return victim.items
	}
}

extension ZKillboard.Killmail: NCKillmail {
	func getAttackers() -> [NCAttacker] {
		return attackers
	}
	
	func getVictim() -> NCVictim {
		return victim
	}
	
	func getItems() -> [NCItem]? {
		return victim.items
	}
}

extension ESI.PlanetaryInteraction.Colony.PlanetType {
	var title: String {
		switch self {
		case .barren:
			return NSLocalizedString("Barren", comment: "PlanetType")
		case .gas:
			return NSLocalizedString("Gas", comment: "PlanetType")
		case .ice:
			return NSLocalizedString("Ice", comment: "PlanetType")
		case .lava:
			return NSLocalizedString("Lava", comment: "PlanetType")
		case .oceanic:
			return NSLocalizedString("Oceanic", comment: "PlanetType")
		case .plasma:
			return NSLocalizedString("Plasma", comment: "PlanetType")
		case .storm:
			return NSLocalizedString("Storm", comment: "PlanetType")
		case .temperate:
			return NSLocalizedString("Temperate", comment: "PlanetType")
		}
	}
}

extension ESI.Wallet.RefType {
	var title: String {
		return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
	}
}

extension ESI {
	class func performAuthorization(from controller: UIViewController) {
		let url = OAuth2.authURL(clientID: ESClientID, callbackURL: ESCallbackURL, scope: ESI.Scope.default, state: "esi")
		controller.present(SFSafariViewController(url: url), animated: true, completion: nil)
	}
}
