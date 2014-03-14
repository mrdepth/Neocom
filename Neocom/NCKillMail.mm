//
//  NCKillMail.m
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCKillMail.h"
#import "EVEOnlineAPI.h"
#import "EVEKillLogKill+Neocom.h"
#import "EVEKillLogVictim+Neocom.h"
#import "EVEDBInvType+Neocom.h"

@implementation NCKillMailPilot

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.allianceID = [aDecoder decodeInt32ForKey:@"allianceID"];
		self.allianceName = [aDecoder decodeObjectForKey:@"allianceName"];
		self.characterID = [aDecoder decodeInt32ForKey:@"characterID"];
		self.characterName = [aDecoder decodeObjectForKey:@"characterName"];
		self.corporationID = [aDecoder decodeInt32ForKey:@"corporationID"];
		self.corporationName = [aDecoder decodeObjectForKey:@"corporationName"];
		self.shipType = [EVEDBInvType invTypeWithTypeID:[aDecoder decodeInt32ForKey:@"shipTypeID"] error:nil];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.allianceID forKey:@"allianceID"];
	[aCoder encodeInt32:self.characterID forKey:@"characterID"];
	[aCoder encodeInt32:self.corporationID forKey:@"corporationID"];
	if (self.allianceName)
		[aCoder encodeObject:self.allianceName forKey:@"allianceName"];
	if (self.characterName)
		[aCoder encodeObject:self.allianceName forKey:@"characterName"];
	if (self.corporationName)
		[aCoder encodeObject:self.allianceName forKey:@"corporationName"];
	if (self.shipType)
		[aCoder encodeInt32:self.shipType.typeID forKey:@"shipTypeID"];

}

@end

@implementation NCKillMailVictim

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.damageTaken = [aDecoder decodeInt32ForKey:@"damageTaken"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.damageTaken forKey:@"damageTaken"];
}

@end

@implementation NCKillMailAttacker

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.securityStatus = [aDecoder decodeFloatForKey:@"securityStatus"];
		self.damageDone = [aDecoder decodeInt32ForKey:@"damageDone"];
		self.finalBlow = [aDecoder decodeBoolForKey:@"finalBlow"];
		self.weaponType = [EVEDBInvType invTypeWithTypeID:[aDecoder decodeInt32ForKey:@"weaponTypeID"] error:nil];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeFloat:self.securityStatus forKey:@"securityStatus"];
	[aCoder encodeInt32:self.damageDone forKey:@"damageDone"];
	[aCoder encodeBool:self.finalBlow forKey:@"finalBlow"];
	if (self.weaponType)
		[aCoder encodeInt32:self.weaponType.typeID forKey:@"weaponTypeID"];
}

@end

@implementation NCKillMailItem

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.destroyed = [aDecoder decodeBoolForKey:@"destroyed"];
		self.qty = [aDecoder decodeInt32ForKey:@"qty"];
		self.type = [EVEDBInvType invTypeWithTypeID:[aDecoder decodeInt32ForKey:@"typeID"] error:nil];
		self.flag = static_cast<EVEInventoryFlag>([aDecoder decodeInt32ForKey:@"flag"]);
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeBool:self.destroyed forKey:@"destroyed"];
	[aCoder encodeInt32:self.qty forKey:@"qty"];
	if (self.type)
		[aCoder encodeInt32:self.type.typeID forKey:@"typeID"];
	[aCoder encodeInt32:self.flag forKey:@"flag"];
	
}

@end

@implementation NCKillMail

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.hiSlots = [aDecoder decodeObjectForKey:@"hiSlots"];
		self.medSlots = [aDecoder decodeObjectForKey:@"medSlots"];
		self.lowSlots = [aDecoder decodeObjectForKey:@"lowSlots"];
		self.rigSlots = [aDecoder decodeObjectForKey:@"rigSlots"];
		self.subsystemSlots = [aDecoder decodeObjectForKey:@"subsystemSlots"];
		self.droneBay = [aDecoder decodeObjectForKey:@"droneBay"];
		self.cargo = [aDecoder decodeObjectForKey:@"cargo"];
		self.attackers = [aDecoder decodeObjectForKey:@"attackers"];
		self.victim = [aDecoder decodeObjectForKey:@"victim"];
		self.solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:[aDecoder decodeInt32ForKey:@"solarSystemID"] error:nil];
		self.killTime = [aDecoder decodeObjectForKey:@"killTime"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.hiSlots)
		[aCoder encodeObject:self.hiSlots forKey:@"hiSlots"];
	if (self.medSlots)
		[aCoder encodeObject:self.medSlots forKey:@"medSlots"];
	if (self.lowSlots)
		[aCoder encodeObject:self.lowSlots forKey:@"lowSlots"];
	if (self.rigSlots)
		[aCoder encodeObject:self.rigSlots forKey:@"rigSlots"];
	if (self.subsystemSlots)
		[aCoder encodeObject:self.subsystemSlots forKey:@"subsystemSlots"];
	if (self.droneBay)
		[aCoder encodeObject:self.droneBay forKey:@"droneBay"];
	if (self.cargo)
		[aCoder encodeObject:self.cargo forKey:@"cargo"];
	if (self.attackers)
		[aCoder encodeObject:self.attackers forKey:@"attackers"];
	if (self.victim)
		[aCoder encodeObject:self.victim forKey:@"victim"];
	if (self.solarSystem)
		[aCoder encodeInt32:self.solarSystem.solarSystemID forKey:@"solarSystemID"];
	if (self.killTime)
		[aCoder encodeObject:self.killTime forKey:@"killTime"];
	
}

- (id) initWithKillLogKill:(EVEKillLogKill*) kill {
	if (self = [super init]) {
		self.victim = [NCKillMailVictim new];
		self.victim.characterName = kill.victim.characterName;
		self.victim.characterID = kill.victim.characterID;
		self.victim.corporationName = kill.victim.corporationName;
		self.victim.corporationID = kill.victim.corporationID;
		self.victim.allianceName = kill.victim.allianceName;
		self.victim.allianceID = kill.victim.allianceID;
		self.victim.shipType =  kill.victim.shipType;
		self.victim.damageTaken = kill.victim.damageTaken;

		self.solarSystem = kill.solarSystem;
		self.killTime = kill.killTime;
		
		NSMutableArray* hiSlots = [NSMutableArray new];
		NSMutableArray* medSlots = [NSMutableArray new];
		NSMutableArray* lowSlots = [NSMutableArray new];
		NSMutableArray* rigSlots = [NSMutableArray new];
		NSMutableArray* subsystems = [NSMutableArray new];
		NSMutableArray* drones = [NSMutableArray new];
		NSMutableArray* cargo = [NSMutableArray new];
		
		for (EVEKillLogItem* item in kill.items) {
			EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
			BOOL hiSlot = NO;
			BOOL medSlot = NO;
			BOOL lowSlot = NO;
			BOOL rigSlot = NO;
			BOOL subsystemSlot = NO;

			if (item.flag == EVEInventoryFlagNone) {
				if ([type category] == NCTypeCategoryModule) {
					switch ([type slot]) {
						case eufe::Module::SLOT_HI:
							hiSlot = YES;
							break;
						case eufe::Module::SLOT_MED:
							medSlot = YES;
							break;
						case eufe::Module::SLOT_LOW:
							lowSlot = YES;
							break;
						case eufe::Module::SLOT_RIG:
							rigSlot = YES;
							break;
						case eufe::Module::SLOT_SUBSYSTEM:
							subsystemSlot = YES;
							break;
						default:
							break;
					}
				}
			}
			else {
				hiSlot = (item.flag >= EVEInventoryFlagHiSlot0 && item.flag <= EVEInventoryFlagHiSlot7);
				medSlot = (item.flag >= EVEInventoryFlagMedSlot0 && item.flag <= EVEInventoryFlagMedSlot7);
				lowSlot = (item.flag >= EVEInventoryFlagLoSlot0 && item.flag <= EVEInventoryFlagLoSlot7);
				rigSlot = (item.flag >= EVEInventoryFlagRigSlot0 && item.flag <= EVEInventoryFlagRigSlot7);
				subsystemSlot = (item.flag >= EVEInventoryFlagSubSystem0 && item.flag <= EVEInventoryFlagSubSystem7);
			}
			
			NSMutableArray* array;
			if (hiSlot)
				array = hiSlots;
			else if (medSlot)
				array = medSlots;
			else if (lowSlot)
				array = lowSlots;
			else if (rigSlot)
				array = rigSlots;
			else if (subsystemSlot)
				array = subsystems;
			else if (item.flag == EVEInventoryFlagDroneBay)
				array = drones;
			else
				array = cargo;

			
			if (item.qtyDestroyed) {
				NCKillMailItem* killMailItem = [NCKillMailItem new];
				killMailItem.type = type;
				killMailItem.qty = item.qtyDestroyed;
				killMailItem.destroyed = YES;
				killMailItem.flag = item.flag;
				[array addObject:killMailItem];
			}
			if (item.qtyDropped) {
				NCKillMailItem* killMailItem = [NCKillMailItem new];
				killMailItem.type = type;
				killMailItem.qty = item.qtyDropped;
				killMailItem.destroyed = NO;
				killMailItem.flag = item.flag;
				[array addObject:killMailItem];
			}
			
		}
		self.hiSlots = hiSlots;
		self.medSlots = medSlots;
		self.lowSlots = lowSlots;
		self.rigSlots = rigSlots;
		self.subsystemSlots = subsystems;
		self.droneBay = drones;
		self.cargo = cargo;
		
		NSMutableArray* attackers = [NSMutableArray new];
		for (EVEKillLogAttacker* item in kill.attackers) {
			NCKillMailAttacker* attacker = [NCKillMailAttacker new];
			attacker.characterName = item.characterName;
			attacker.characterID = item.characterID;
			attacker.corporationName = item.corporationName;
			attacker.corporationID = item.corporationID;
			attacker.allianceName = item.allianceName;
			attacker.allianceID = item.allianceID;
			attacker.shipType = [EVEDBInvType invTypeWithTypeID:item.shipTypeID error:nil];
			attacker.weaponType = [EVEDBInvType invTypeWithTypeID:item.weaponTypeID error:nil];
			attacker.securityStatus = item.securityStatus;
			attacker.damageDone = item.damageDone;
			attacker.finalBlow = item.finalBlow;
			[attackers addObject:attacker];
		}
		[attackers sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"finalBlow" ascending:NO],
										  [NSSortDescriptor sortDescriptorWithKey:@"damageDone" ascending:NO]]];
		self.attackers = attackers;
	}
	return self;
}

- (id) initWithKillNetLogEntry:(EVEKillNetLogEntry*) kill {
	if (self = [super init]) {
	}
	return self;
}

@end