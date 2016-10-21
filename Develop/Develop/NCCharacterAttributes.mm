//
//  NCCharacterAttributes.m
//  Develop
//
//  Created by Artem Shimanski on 21.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCharacterAttributes.h"
#include <map>
#include <limits>
#import <EVEAPI/EVEAPI.h>
#import "NCDatabase.h"

@interface NCCharacterAttributes ()
- (int32_t) effectiveAttributeValueWithAttributeID:(int32_t) attributeID;
@end

@implementation NCCharacterAttributes

+ (instancetype) defaultCharacterAttributes {
	NCCharacterAttributes* attributes = [[NCCharacterAttributes alloc] init];
	attributes.charisma = 19;
	attributes.intelligence = 20;
	attributes.memory = 20;
	attributes.perception = 20;
	attributes.willpower = 20;
	return attributes;
}

+ (instancetype) characterAttributesWithCharacterSheet:(EVECharacterSheet*) characterSheet {
	if (characterSheet) {
		NCCharacterAttributes* attributes = [self new];
		attributes.charisma = characterSheet.attributes.charisma;
		attributes.intelligence = characterSheet.attributes.intelligence;
		attributes.memory = characterSheet.attributes.memory;
		attributes.perception = characterSheet.attributes.perception;
		attributes.willpower = characterSheet.attributes.willpower;

		[NCDatabase.sharedDatabase performTaskAndWait:^(NSManagedObjectContext *managedObjectContext) {
		}];
		/*NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		[databaseManagedObjectContext performBlockAndWait:^{
			for (EVECharacterSheetImplant* implant in characterSheet.implants) {
				NCDBInvType* type = [databaseManagedObjectContext invTypeWithTypeID:implant.typeID];
				self.charisma += [(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCCharismaBonusAttributeID)] value];
				self.intelligence += [(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCIntelligenceBonusAttributeID)] value];
				self.memory += [(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCMemoryBonusAttributeID)] value];
				self.perception += [(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCPerceptionBonusAttributeID)] value];
				self.willpower += [(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCWillpowerBonusAttributeID)] value];
			}
		}];*/
		return attributes;
	}
	else
		return [NCCharacterAttributes defaultCharacterAttributes];
}

- (float) skillpointsPerSecondForSkill:(NCDBInvType*) skill {
	__block float skillpointsPerSecond = 0;
/*	[skill.managedObjectContext performBlockAndWait:^{
		NCDBDgmTypeAttribute *primaryAttribute = skill.attributesDictionary[@(NCPrimaryAttributeAttribteID)];
		NCDBDgmTypeAttribute *secondaryAttribute = skill.attributesDictionary[@(NCSecondaryAttributeAttribteID)];
		skillpointsPerSecond = [self skillpointsPerSecondWithPrimaryAttribute:primaryAttribute.value secondaryAttribute:secondaryAttribute.value];
	}];*/
	return skillpointsPerSecond;
}

- (float) skillpointsPerSecondWithPrimaryAttribute:(int32_t) primaryAttributeID secondaryAttribute:(int32_t) secondaryAttributeID {
	int32_t effectivePrimaryAttribute = [self effectiveAttributeValueWithAttributeID:primaryAttributeID];
	int32_t effectiveSecondaryAttribute = [self effectiveAttributeValueWithAttributeID:secondaryAttributeID];
	return (effectivePrimaryAttribute + effectiveSecondaryAttribute / 2.0) / 60.0;
}


#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt32:self.charisma forKey:@"charisma"];
	[aCoder encodeInt32:self.intelligence forKey:@"intelligence"];
	[aCoder encodeInt32:self.memory forKey:@"memory"];
	[aCoder encodeInt32:self.perception forKey:@"perception"];
	[aCoder encodeInt32:self.willpower forKey:@"willpower"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.charisma = [aDecoder decodeInt32ForKey:@"charisma"];
		self.intelligence = [aDecoder decodeInt32ForKey:@"intelligence"];
		self.memory = [aDecoder decodeInt32ForKey:@"memory"];
		self.perception = [aDecoder decodeInt32ForKey:@"perception"];
		self.willpower = [aDecoder decodeInt32ForKey:@"willpower"];
	}
	return self;
}

#pragma mark - Private

- (int32_t) effectiveAttributeValueWithAttributeID:(int32_t) attributeID {
	switch (attributeID) {
		case NCCharismaAttributeID:
			return self.charisma;
		case NCIntelligenceAttributeID:
			return self.intelligence;
		case NCMemoryAttributeID:
			return self.memory;
		case NCPerceptionAttributeID:
			return self.perception;
		case NCWillpowerAttributeID:
			return self.willpower;
		default:
			break;
	}
	return 0;
}

@end
