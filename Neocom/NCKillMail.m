//
//  NCKillMail.m
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCKillMail.h"


@implementation NCKillMailPilot

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.allianceID = [aDecoder decodeIntegerForKey:@"allianceID"];
		self.allianceName = [aDecoder decodeObjectForKey:@"allianceName"];
		self.characterID = [aDecoder decodeIntegerForKey:@"characterID"];
		self.characterName = [aDecoder decodeObjectForKey:@"characterName"];
		self.corporationID = [aDecoder decodeIntegerForKey:@"corporationID"];
		self.corporationName = [aDecoder decodeObjectForKey:@"corporationName"];
		self.shipType = [EVEDBInvType invTypeWithTypeID:[aDecoder decodeIntegerForKey:@"shipTypeID"] error:nil];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInteger:self.allianceID forKey:@"allianceID"];
	[aCoder encodeInteger:self.characterID forKey:@"characterID"];
	[aCoder encodeInteger:self.corporationID forKey:@"corporationID"];
	if (self.allianceName)
		[aCoder encodeObject:self.allianceName forKey:@"allianceName"];
	if (self.characterName)
		[aCoder encodeObject:self.allianceName forKey:@"characterName"];
	if (self.corporationName)
		[aCoder encodeObject:self.allianceName forKey:@"corporationName"];
	if (self.shipType)
		[aCoder encodeInteger:self.shipType.typeID forKey:@"shipTypeID"];

}

@end

@implementation NCKillMailVictim

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.damageTaken = [aDecoder decodeIntegerForKey:@"damageTaken"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInteger:self.damageTaken forKey:@"damageTaken"];
}

@end

@implementation NCKillMailAttacker

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.securityStatus = [aDecoder decodeFloatForKey:@"securityStatus"];
		self.damageDone = [aDecoder decodeIntegerForKey:@"damageDone"];
		self.finalBlow = [aDecoder decodeBoolForKey:@"finalBlow"];
		self.weaponType = [EVEDBInvType invTypeWithTypeID:[aDecoder decodeIntegerForKey:@"weaponTypeID"] error:nil];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeFloat:self.securityStatus forKey:@"securityStatus"];
	[aCoder encodeInteger:self.damageDone forKey:@"damageDone"];
	[aCoder encodeBool:self.finalBlow forKey:@"finalBlow"];
	if (self.weaponType)
		[aCoder encodeInteger:self.weaponType.typeID forKey:@"weaponTypeID"];
}

@end

@implementation NCKillMailItem

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.destroyed = [aDecoder decodeBoolForKey:@"destroyed"];
		self.qty = [aDecoder decodeIntegerForKey:@"qty"];
		self.type = [EVEDBInvType invTypeWithTypeID:[aDecoder decodeIntegerForKey:@"typeID"] error:nil];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeBool:self.destroyed forKey:@"destroyed"];
	[aCoder encodeInteger:self.qty forKey:@"qty"];
	if (self.type)
		[aCoder encodeInteger:self.type.typeID forKey:@"typeID"];
	
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
		self.solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:[aDecoder decodeIntegerForKey:@"solarSystemID"] error:nil];
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
		[aCoder encodeInteger:self.solarSystem.solarSystemID forKey:@"solarSystemID"];
	if (self.killTime)
		[aCoder encodeObject:self.killTime forKey:@"killTime"];
	
}

- (id) initWithKillLogKill:(EVEKillLogKill*) kill {
	if (self = [super init]) {
	}
	return self;
}

- (id) initWithKillNetLogEntry:(EVEKillNetLogEntry*) kill {
	if (self = [super init]) {
	}
	return self;
}

@end