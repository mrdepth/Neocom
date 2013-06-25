//
//  CharacterEqualSkills.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CharacterEqualSkills.h"
#import "EVEDBAPI.h"

@implementation CharacterEqualSkills

+ (id) characterWithSkillsLevel:(NSInteger) level {
	return [[CharacterEqualSkills alloc] initWithSkillsLevel:level];
}

- (id) initWithSkillsLevel:(NSInteger) level {
	if (self = [super init]) {
		self.characterID = level;
		self.name = [[NSString alloc] initWithFormat:NSLocalizedString(@"All Skills %d", nil), level];
	}
	return self;
}

- (NSMutableDictionary*) skills {
	NSMutableDictionary* skills = [super skills];
	if (!skills) {
		skills = [[NSMutableDictionary alloc] init];
		if (self.characterID > 0) {
			
			EVEDBDatabase *database = [EVEDBDatabase sharedDatabase];
			if (!database) {
				return nil;
			}
			NSError *error = [database execSQLRequest:@"SELECT A.typeID FROM invTypes AS A, invGroups AS B WHERE A.groupID=B.groupID AND B.categoryID=16 AND A.published=1;"
										  resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
											  NSInteger typeID = sqlite3_column_int(stmt, 0);
											  [skills setValue:@(self.characterID) forKey:[NSString stringWithFormat:@"%d", typeID]];
										  }];
			if (error) {
				return nil;
			}
		}
		self.skills = skills;
	}
	return skills;
}

- (NSString*) guid {
	return [NSString stringWithFormat:@"s%d", self.characterID];
}

@end