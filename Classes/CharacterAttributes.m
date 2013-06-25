//
//  CharacterAttributes.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CharacterAttributes.h"
#import "EVEDBAPI.h"

@interface CharacterAttributes()
- (NSInteger) effectiveAttributeValueWithAttributeID:(NSInteger) attributeID;
@end

@implementation CharacterAttributes
	
+ (CharacterAttributes*) defaultCharacterAttributes {
	CharacterAttributes* attributes = [[CharacterAttributes alloc] init];
	attributes.charisma = 19;
	attributes.intelligence = 20;
	attributes.memory = 20;
	attributes.perception = 20;
	attributes.willpower = 20;
	return attributes;
}

- (float) skillpointsPerSecondForSkill:(EVEDBInvType*) skill {
	EVEDBDgmTypeAttribute *primaryAttribute = [skill.attributesDictionary valueForKey:@"180"];
	EVEDBDgmTypeAttribute *secondaryAttribute = [skill.attributesDictionary valueForKey:@"181"];
	NSInteger effectivePrimaryAttribute = [self effectiveAttributeValueWithAttributeID:primaryAttribute.value];
	NSInteger effectiveSecondaryAttribute = [self effectiveAttributeValueWithAttributeID:secondaryAttribute.value];
	return (effectivePrimaryAttribute + effectiveSecondaryAttribute / 2.0) / 60.0;
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