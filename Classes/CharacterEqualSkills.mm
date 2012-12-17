//
//  CharacterEqualSkills.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CharacterEqualSkills.h"
#import "EVEDBAPI.h"

@interface CharacterEqualSkills(Private)
- (void) didReceiveRecord: (NSDictionary*) record;
@end

@implementation CharacterEqualSkills

+ (id) characterWithSkillsLevel:(NSInteger) level {
	return [[[CharacterEqualSkills alloc] initWithSkillsLevel:level] autorelease];
}

- (id) initWithSkillsLevel:(NSInteger) level {
	if (self = [super init]) {
		characterID = level;
		name = [[NSString alloc] initWithFormat:NSLocalizedString(@"All Skills %d", nil), level];
	}
	return self;
}

- (void) dealloc {
	[super dealloc];
}

- (NSMutableDictionary*) skills {
	if (!skills) {
		skills = [[NSMutableDictionary alloc] init];
		if (characterID > 0) {
			
			EVEDBDatabase *database = [EVEDBDatabase sharedDatabase];
			if (!database) {
				[self release];
				return nil;
			}
			NSError *error = [database execWithSQLRequest:@"SELECT A.typeID FROM invTypes AS A, invGroups AS B WHERE A.groupID=B.groupID AND B.categoryID=16 AND A.published=1;"
												   target:self
												   action:@selector(didReceiveRecord:)];
			if (error) {
				[self release];
				return nil;
			}
		}
	}
	return skills;
}

- (NSString*) guid {
	return [NSString stringWithFormat:@"s%d", characterID];
}

@end

@implementation CharacterEqualSkills(Private)

- (void) didReceiveRecord: (NSDictionary*) record {
	NSString* typeID = [record valueForKey:@"typeID"];
	[skills setValue:[NSNumber numberWithInteger:characterID] forKey:typeID];
}

@end