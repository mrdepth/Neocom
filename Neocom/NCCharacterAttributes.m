//
//  NCCharacterAttributes.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCCharacterAttributes.h"
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"

@interface NCCharacterAttributes ()
- (NSInteger) effectiveAttributeValueWithAttributeID:(NSInteger) attributeID;
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

- (id) initWithCharacterSheet:(EVECharacterSheet*) characterSheet {
	if (self = [super init]) {
		if (characterSheet) {
			self.intelligence = characterSheet.attributes.intelligence;
			
			self.charisma = characterSheet.attributes.charisma;
			self.intelligence = characterSheet.attributes.intelligence;
			self.memory = characterSheet.attributes.memory;
			self.perception = characterSheet.attributes.perception;
			self.willpower = characterSheet.attributes.willpower;
			
			for (EVECharacterSheetAttributeEnhancer *enhancer in characterSheet.attributeEnhancers) {
				switch (enhancer.attribute) {
					case EVECharacterAttributeCharisma:
						self.charisma += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributeIntelligence:
						self.intelligence += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributeMemory:
						self.memory += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributePerception:
						self.perception += enhancer.augmentatorValue;
						break;
					case EVECharacterAttributeWillpower:
						self.willpower += enhancer.augmentatorValue;
						break;
				}
			}
		}
		else {
			self.charisma = 19;
			self.intelligence = 20;
			self.memory = 20;
			self.perception = 20;
			self.willpower = 20;
		}
	}
	return self;
}

- (float) skillpointsPerSecondForSkill:(EVEDBInvType*) skill {
	EVEDBDgmTypeAttribute *primaryAttribute = skill.attributesDictionary[@(180)];
	EVEDBDgmTypeAttribute *secondaryAttribute = skill.attributesDictionary[@(181)];
	NSInteger effectivePrimaryAttribute = [self effectiveAttributeValueWithAttributeID:primaryAttribute.value];
	NSInteger effectiveSecondaryAttribute = [self effectiveAttributeValueWithAttributeID:secondaryAttribute.value];
	return (effectivePrimaryAttribute + effectiveSecondaryAttribute / 2.0) / 60.0;
}

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInteger:self.charisma forKey:@"charisma"];
	[aCoder encodeInteger:self.intelligence forKey:@"intelligence"];
	[aCoder encodeInteger:self.memory forKey:@"memory"];
	[aCoder encodeInteger:self.perception forKey:@"perception"];
	[aCoder encodeInteger:self.willpower forKey:@"willpower"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.charisma = [aDecoder decodeIntegerForKey:@"charisma"];
		self.intelligence = [aDecoder decodeIntegerForKey:@"intelligence"];
		self.memory = [aDecoder decodeIntegerForKey:@"memory"];
		self.perception = [aDecoder decodeIntegerForKey:@"perception"];
		self.willpower = [aDecoder decodeIntegerForKey:@"willpower"];
	}
	return self;
}

#pragma mark - Private

- (NSInteger) effectiveAttributeValueWithAttributeID:(NSInteger) attributeID {
	switch (attributeID) {
		case 164:
			return self.charisma;
			break;
		case 165:
			return self.intelligence;
			break;
		case 166:
			return self.memory;
			break;
		case 167:
			return self.perception;
			break;
		case 168:
			return self.willpower;
			break;
		default:
			break;
	}
	return 0;
}

@end