//
//  NCCharacterAttributes.m
//  Neocom
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
		NCCharacterAttributes* characterAttributes = [self new];
		characterAttributes.charisma = characterSheet.attributes.charisma;
		characterAttributes.intelligence = characterSheet.attributes.intelligence;
		characterAttributes.memory = characterSheet.attributes.memory;
		characterAttributes.perception = characterSheet.attributes.perception;
		characterAttributes.willpower = characterSheet.attributes.willpower;

		[NCDatabase.sharedDatabase performTaskAndWait:^(NSManagedObjectContext *managedObjectContext) {
			NCFetchedCollection<NCDBInvType*>* invTypes = [NCDBInvType invTypesWithManagedObjectContext:managedObjectContext];
			for (EVECharacterSheetImplant* implant in characterSheet.implants) {
				NCDBInvType* type = invTypes[implant.typeID];
				NCFetchedCollection<NCDBDgmTypeAttribute*>* attributes = type.allAttributes;
				characterAttributes.charisma += attributes[NCCharismaBonusAttributeID].value;
				characterAttributes.intelligence += attributes[NCIntelligenceBonusAttributeID].value;
				characterAttributes.memory += attributes[NCMemoryBonusAttributeID].value;
				characterAttributes.perception += attributes[NCPerceptionBonusAttributeID].value;
				characterAttributes.willpower += attributes[NCWillpowerBonusAttributeID].value;
			}
		}];
		return characterAttributes;
	}
	else
		return [NCCharacterAttributes defaultCharacterAttributes];
}

- (float) skillpointsPerSecondForSkill:(NCDBInvType*) skill {
	__block float skillpointsPerSecond = 0;
	[skill.managedObjectContext performBlockAndWait:^{
		NCFetchedCollection<NCDBDgmTypeAttribute*>* attributes = skill.allAttributes;
		NCDBDgmTypeAttribute *primaryAttribute = attributes[NCPrimaryAttributeAttribteID];
		NCDBDgmTypeAttribute *secondaryAttribute = attributes[NCSecondaryAttributeAttribteID];
		skillpointsPerSecond = [self skillpointsPerSecondWithPrimaryAttribute:primaryAttribute.value secondaryAttribute:secondaryAttribute.value];
	}];
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
