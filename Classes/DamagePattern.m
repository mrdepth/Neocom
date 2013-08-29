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

+ (id) uniformDamagePattern {
	DamagePattern* damagePattern = [[DamagePattern alloc] init];
	damagePattern.patternName = NSLocalizedString(@"Uniform", nil);
	damagePattern.uuid = @"uniform";
	return damagePattern;
}

+ (id) damagePatternWithNPCType:(EVEDBInvType*) type {
	return [[DamagePattern alloc] initWithNPCType:type];
}

- (id) initWithNPCType:(EVEDBInvType*) type {
	if (self = [super init]) {
		self.patternName = type.typeName;
		
		EVEDBDgmTypeAttribute* emDamageAttribute = type.attributesDictionary[@(114)];
		EVEDBDgmTypeAttribute* explosiveDamageAttribute = type.attributesDictionary[@(116)];
		EVEDBDgmTypeAttribute* kineticDamageAttribute = type.attributesDictionary[@(117)];
		EVEDBDgmTypeAttribute* thermalDamageAttribute = type.attributesDictionary[@(1180)];
		EVEDBDgmTypeAttribute* damageMultiplierAttribute = type.attributesDictionary[@(64)];
		EVEDBDgmTypeAttribute* missileDamageMultiplierAttribute = type.attributesDictionary[@(212)];
		EVEDBDgmTypeAttribute* missileTypeIDAttribute = type.attributesDictionary[@(507)];
		
		EVEDBDgmTypeAttribute* turretFireSpeedAttribute = type.attributesDictionary[@(51)];
		EVEDBDgmTypeAttribute* missileLaunchDurationAttribute = type.attributesDictionary[@(506)];
		
		
		//Turrets damage
		
		float emDamageTurret = 0;
		float explosiveDamageTurret = 0;
		float kineticDamageTurret = 0;
		float thermalDamageTurret = 0;
		float intervalTurret = 0;
		
		if (type.effectsDictionary[@(10)] || type.effectsDictionary[@(1086)]) {
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
		
		if (type.effectsDictionary[@(569)]) {
			EVEDBInvType* missile = [EVEDBInvType invTypeWithTypeID:(NSInteger)[missileTypeIDAttribute value] error:nil];
			if (missile) {
				EVEDBDgmTypeAttribute* emDamageAttribute = missile.attributesDictionary[@(114)];
				EVEDBDgmTypeAttribute* explosiveDamageAttribute = missile.attributesDictionary[@(116)];
				EVEDBDgmTypeAttribute* kineticDamageAttribute = missile.attributesDictionary[@(117)];
				EVEDBDgmTypeAttribute* thermalDamageAttribute = missile.attributesDictionary[@(118)];
				
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
			_emAmount = _thermalAmount = _kineticAmount = _explosiveAmount = 0.25;
		}
		else {
			self.emAmount = emDPS / totalDPS;
			self.thermalAmount = thermalDPS / totalDPS;
			self.kineticAmount = kineticDPS / totalDPS;
			self.explosiveAmount = explosiveDPS / totalDPS;
		}
	}
	return self;
}

- (id) init {
	if (self = [super init]) {
		_emAmount = _thermalAmount = _kineticAmount = _explosiveAmount = 0.25;
		self.patternName = NSLocalizedString(@"Pattern Name", nil);
		self.uuid = [NSString uuidString];
	}
	return self;
}

- (BOOL) isEqual:(id)object {
	if ([object isKindOfClass:[self class]])
		return [self.uuid isEqual:[object uuid]];
	else
		return NO;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.patternName = [aDecoder decodeObjectForKey:@"patternName"];
		self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
		self.emAmount = [aDecoder decodeFloatForKey:@"emAmount"];
		self.thermalAmount = [aDecoder decodeFloatForKey:@"thermalAmount"];
		self.kineticAmount = [aDecoder decodeFloatForKey:@"kineticAmount"];
		self.explosiveAmount = [aDecoder decodeFloatForKey:@"explosiveAmount"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.patternName forKey:@"patternName"];
	[aCoder encodeObject:self.uuid forKey:@"uuid"];
	[aCoder encodeFloat:self.emAmount forKey:@"emAmount"];
	[aCoder encodeFloat:self.thermalAmount forKey:@"thermalAmount"];
	[aCoder encodeFloat:self.kineticAmount forKey:@"kineticAmount"];
	[aCoder encodeFloat:self.explosiveAmount forKey:@"explosiveAmount"];
}

@end
