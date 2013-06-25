//
//  CharacterCustom.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CharacterCustom.h"

@implementation CharacterCustom

+ (id) characterWithCharacter:(Character*) character {
	return [[CharacterCustom alloc] initWithCharacter:character];
}

- (id) init {
	if (self = [super init]) {
		NSString* path = [Character charactersDirectory];
		NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
		self.characterID = -1;
		for (NSString* fileName in items) {
			if ([fileName characterAtIndex:0] == 'c') {
				NSInteger index = [[fileName substringWithRange:NSMakeRange(1, fileName.length - 7)] integerValue];
				if (index > self.characterID)
					self.characterID = index;
			}
		}
		self.characterID = self.characterID + 1;
		self.skills = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id) initWithCharacter:(Character*) character {
	if (self = [self init]) {
		self.name = character.name;
		self.skills = [NSMutableDictionary dictionaryWithDictionary:character.skills];
	}
	return self;
}

- (NSString*) guid {
	return [NSString stringWithFormat:@"c%d", self.characterID];
}

@end
