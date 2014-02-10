//
//  NCFitCharacter.m
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCFitCharacter.h"
#import "NCStorage.h"
#import "NCAccount.h"

@interface NCFitCharacter()
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, assign) NSInteger skillsLevel;

@end

@implementation NCFitCharacter

@dynamic name;
@dynamic skills;

@synthesize account = _account;
@synthesize skillsLevel = _skillsLevel;

+ (NSArray*) characters {
	NCStorage* storage = [NCStorage sharedStorage];
	__block NSArray *fetchedObjects = nil;
	[storage.managedObjectContext performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:storage.managedObjectContext];
		[fetchRequest setEntity:entity];
		fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
		
		NSError *error = nil;
		fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	}];
	return fetchedObjects;
}

+ (instancetype) characterWithAccount:(NCAccount*) account {
	if (account.accountType == NCAccountTypeCorporate)
		return nil;
	
	NCStorage* storage = [NCStorage sharedStorage];
	NCFitCharacter* character = [[NCFitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:nil];
	character.account = account;
	character.name = account.characterSheet.name;
	return character;
}

+ (instancetype) characterWithSkillsLevel:(NSInteger) skillsLevel {
	NCStorage* storage = [NCStorage sharedStorage];
	NCFitCharacter* character = [[NCFitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:nil];
	character.skillsLevel = skillsLevel;
	character.name = [NSString stringWithFormat:NSLocalizedString(@"All Skills %d", nil), skillsLevel];
	return character;
}

- (NSDictionary*) skills {
	@synchronized(self) {
		[self willAccessValueForKey:@"skills"];
		NSDictionary* skills = [self primitiveValueForKey:@"skills"];
		[self didAccessValueForKey:@"skills"];
		
		if (!skills) {
			NSMutableDictionary* mSkills = [NSMutableDictionary new];
			if (self.account) {
				for (EVECharacterSheetSkill* skill in self.account.characterSheet.skills)
					mSkills[@(skill.typeID)] = @(skill.level);
			}
			else {
				NSNumber* level = @(self.skillsLevel);
				[[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT A.typeID FROM invTypes AS A, invGroups AS B WHERE A.groupID=B.groupID AND B.categoryID=16 AND A.published=1;"
												   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
													   NSInteger typeID = sqlite3_column_int(stmt, 0);
													   mSkills[@(typeID)] = level;
												   }];
			}
			skills = mSkills;
			self.skills = skills;
		}
		
		return skills;
	}
}


@end
