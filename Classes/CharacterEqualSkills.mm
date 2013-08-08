//
//  CharacterEqualSkills.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CharacterEqualSkills.h"
#import "EVEDBAPI.h"

@interface CharacterEqualSkills()
@property (nonatomic, assign) BOOL level;

@end

@implementation CharacterEqualSkills
@synthesize name = _name;
@synthesize skillsDictionary = _skillsDictionary;

+ (id) characterWithSkillsLevel:(NSInteger) level {
	return [[CharacterEqualSkills alloc] initWithSkillsLevel:level];
}

- (id) initWithSkillsLevel:(NSInteger) level {
	if (self = [super init]) {
		self.level = level;
		self.name = [[NSString alloc] initWithFormat:NSLocalizedString(@"All Skills %d", nil), level];
	}
	return self;
}

- (NSMutableDictionary*) skillsDictionary {
	if (!_skillsDictionary) {
		_skillsDictionary = [NSMutableDictionary new];
		if (self.level > 0) {
			
			EVEDBDatabase *database = [EVEDBDatabase sharedDatabase];
			if (!database) {
				return nil;
			}
			NSNumber* level = @(self.level);
			NSError *error = [database execSQLRequest:@"SELECT A.typeID FROM invTypes AS A, invGroups AS B WHERE A.groupID=B.groupID AND B.categoryID=16 AND A.published=1;"
										  resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
											  NSInteger typeID = sqlite3_column_int(stmt, 0);
											  _skillsDictionary[@(typeID)] = level;
										  }];
			if (error) {
				return nil;
			}
		}
	}
	return _skillsDictionary;
}

- (BOOL) isReadonly {
	return YES;
}

- (boost::shared_ptr<std::map<eufe::TypeID, int> >) skillsMap {
	boost::shared_ptr<std::map<eufe::TypeID, int> > levels(new std::map<eufe::TypeID, int>);
	[self.skillsDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NSNumber* level, BOOL *stop) {
		(*levels)[static_cast<eufe::TypeID>([key intValue])] = [level intValue];
	}];
	return levels;
}

@end