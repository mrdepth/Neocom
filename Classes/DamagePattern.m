//
//  DamagePattern.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DamagePattern.h"
#import "NSString+UUID.h"
#import "EVEDBAPI.h"

@implementation DamagePattern
@synthesize emAmount;
@synthesize thermalAmount;
@synthesize kineticAmount;
@synthesize explosiveAmount;
@synthesize patternName;
@synthesize uuid;

+ (id) uniformDamagePattern {
	DamagePattern* damagePattern = [[[DamagePattern alloc] init] autorelease];
	damagePattern.patternName = @"Uniform";
	damagePattern.uuid = @"uniform";
	return damagePattern;
}

+ (id) damagePatternWithNPCType:(EVEDBInvType*) type {
	return [[[DamagePattern alloc] initWithNPCType:type] autorelease];
}

- (id) initWithNPCType:(EVEDBInvType*) type {
	if (self = [super init]) {
		self.patternName = type.typeName;
		
		EVEDBDgmTypeAttribute* emDamageAttribute = [type.attributesDictionary valueForKey:@"114"];
		EVEDBDgmTypeAttribute* explosiveDamageAttribute = [type.attributesDictionary valueForKey:@"116"];
		EVEDBDgmTypeAttribute* kineticDamageAttribute = [type.attributesDictionary valueForKey:@"117"];
		EVEDBDgmTypeAttribute* thermalDamageAttribute = [type.attributesDictionary valueForKey:@"118"];
		EVEDBDgmTypeAttribute* damageMultiplierAttribute = [type.attributesDictionary valueForKey:@"64"];
		EVEDBDgmTypeAttribute* missileDamageMultiplierAttribute = [type.attributesDictionary valueForKey:@"212"];
		EVEDBDgmTypeAttribute* missileTypeIDAttribute = [type.attributesDictionary valueForKey:@"507"];
		
		EVEDBDgmTypeAttribute* turretFireSpeedAttribute = [type.attributesDictionary valueForKey:@"51"];
		EVEDBDgmTypeAttribute* missileLaunchDurationAttribute = [type.attributesDictionary valueForKey:@"506"];
		
		
		//Turrets damage
		
		float emDamageTurret = 0;
		float explosiveDamageTurret = 0;
		float kineticDamageTurret = 0;
		float thermalDamageTurret = 0;
		float intervalTurret = 0;
		
		if ([type.effectsDictionary valueForKey:@"10"] || [type.effectsDictionary valueForKey:@"1086"]) {
			float damageMultiplier = [damageMultiplierAttribute value];
			if (damageMultiplier == 0)
				damageMultiplier = 1;
			
			emDamageTurret = [emDamageAttribute value] * damageMultiplier;
			explosiveDamageTurret = [explosiveDamageAttribute value] * damageMultiplier;
			kineticDamageTurret = [kineticDamageAttribute value] * damageMultiplier;
			thermalDamageTurret = [thermalDamageAttribute value] * damageMultiplier;
			intervalTurret = [turretFireSpeedAttribute value] / 1000.0;
		}
		
		//Missiles damage
		float emDamageMissile = 0;
		float explosiveDamageMissile = 0;
		float kineticDamageMissile = 0;
		float thermalDamageMissile = 0;
		float intervalMissile = 0;
		
		if ([type.effectsDictionary valueForKey:@"569"]) {
			EVEDBInvType* missile = [EVEDBInvType invTypeWithTypeID:(NSInteger)[missileTypeIDAttribute value] error:nil];
			if (missile) {
				EVEDBDgmTypeAttribute* emDamageAttribute = [missile.attributesDictionary valueForKey:@"114"];
				EVEDBDgmTypeAttribute* explosiveDamageAttribute = [missile.attributesDictionary valueForKey:@"116"];
				EVEDBDgmTypeAttribute* kineticDamageAttribute = [missile.attributesDictionary valueForKey:@"117"];
				EVEDBDgmTypeAttribute* thermalDamageAttribute = [missile.attributesDictionary valueForKey:@"118"];
				
				float missileDamageMultiplier = [missileDamageMultiplierAttribute value];
				if (missileDamageMultiplier == 0)
					missileDamageMultiplier = 1;
				
				emDamageMissile = [emDamageAttribute value] * missileDamageMultiplier;
				explosiveDamageMissile = [explosiveDamageAttribute value] * missileDamageMultiplier;
				kineticDamageMissile = [kineticDamageAttribute value] * missileDamageMultiplier;
				thermalDamageMissile = [thermalDamageAttribute value] * missileDamageMultiplier;
				intervalMissile = [missileLaunchDurationAttribute value] / 1000.0;
				
			}
		}

		if (intervalTurret == 0)
			intervalTurret = 1;
		if (intervalMissile == 0)
			intervalMissile = 1;
		
		float emDPSTurret = emDamageTurret / intervalTurret;
		float explosiveDPSTurret = explosiveDamageTurret / intervalTurret;
		float kineticDPSTurret = kineticDamageTurret / intervalTurret;
		float thermalDPSTurret = thermalDamageTurret / intervalTurret;
		float totalDPSTurret = emDPSTurret + explosiveDPSTurret + kineticDPSTurret + thermalDPSTurret;
		
		
		float emDPSMissile = emDamageMissile / intervalMissile;
		float explosiveDPSMissile = explosiveDamageMissile / intervalMissile;
		float kineticDPSMissile = kineticDamageMissile / intervalMissile;
		float thermalDPSMissile = thermalDamageMissile / intervalMissile;
		float totalDPSMissile = emDPSMissile + explosiveDPSMissile + kineticDPSMissile + thermalDPSMissile;
		
		float emDPS = emDPSTurret + emDPSMissile;
		float explosiveDPS = explosiveDPSTurret + explosiveDPSMissile;
		float kineticDPS = kineticDPSTurret + kineticDPSMissile;
		float thermalDPS = thermalDPSTurret + thermalDPSMissile;
		float totalDPS = totalDPSTurret + totalDPSMissile;
		
		if (totalDPS == 0) {
			emAmount = thermalAmount = kineticAmount = explosiveAmount = 0.25;
		}
		else {
			emAmount = emDPS / totalDPS;
			thermalAmount = thermalDPS / totalDPS;
			kineticAmount = kineticDPS / totalDPS;
			explosiveAmount = explosiveDPS / totalDPS;
		}
	}
	return self;
}

- (id) init {
	if (self = [super init]) {
		emAmount = thermalAmount = kineticAmount = explosiveAmount = 0.25;
		self.patternName = @"Pattern Name";
		self.uuid = [NSString uuidString];
	}
	return self;
}

- (void) dealloc {
	[patternName release];
	[uuid release];
	[super dealloc];
}

- (BOOL) isEqual:(id)object {
	if ([object isKindOfClass:[self class]])
		return [uuid isEqual:[object uuid]];
	else
		return NO;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.patternName = [aDecoder decodeObjectForKey:@"patternName"];
		self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
		emAmount = [aDecoder decodeFloatForKey:@"emAmount"];
		thermalAmount = [aDecoder decodeFloatForKey:@"thermalAmount"];
		kineticAmount = [aDecoder decodeFloatForKey:@"kineticAmount"];
		explosiveAmount = [aDecoder decodeFloatForKey:@"explosiveAmount"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:patternName forKey:@"patternName"];
	[aCoder encodeObject:uuid forKey:@"uuid"];
	[aCoder encodeFloat:emAmount forKey:@"emAmount"];
	[aCoder encodeFloat:thermalAmount forKey:@"thermalAmount"];
	[aCoder encodeFloat:kineticAmount forKey:@"kineticAmount"];
	[aCoder encodeFloat:explosiveAmount forKey:@"explosiveAmount"];
}

@end
