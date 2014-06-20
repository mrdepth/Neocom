//
//  NCFitCharacter.m
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCFitCharacter.h"
#import "NCAccount.h"

@interface NCFitCharacter()
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, assign) NSInteger skillsLevel;

@end

@implementation NCStorage(NCFitCharacter)

- (NSArray*) characters {
	__block NSArray *fetchedObjects = nil;
	NSManagedObjectContext* context = [NSThread isMainThread] ? self.managedObjectContext : self.backgroundManagedObjectContext;
	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:context];
		[fetchRequest setEntity:entity];
		fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
		
		NSError *error = nil;
		fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
	}];
	return fetchedObjects;
}

- (NCFitCharacter*) characterWithAccount:(NCAccount*) account {
	if (account.accountType == NCAccountTypeCorporate)
		return nil;
	
	NCFitCharacter* character = [[NCFitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:nil];
	character.account = account;
	character.name = account.characterSheet.name;
	return character;
}

- (NCFitCharacter*) characterWithSkillsLevel:(NSInteger) skillsLevel {
	NCFitCharacter* character = [[NCFitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:nil];
	character.skillsLevel = skillsLevel;
	character.name = [NSString stringWithFormat:NSLocalizedString(@"All Skills %d", nil), (int32_t) skillsLevel];
	return character;
}

@end

@implementation NCFitCharacter

@dynamic name;
@dynamic skills;

@synthesize account = _account;
@synthesize skillsLevel = _skillsLevel;


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
				NCDatabase* database = [NCDatabase sharedDatabase];
				[database.backgroundManagedObjectContext performBlockAndWait:^{
					NSEntityDescription* entity = [NSEntityDescription entityForName:@"InvType" inManagedObjectContext:database.backgroundManagedObjectContext];
					NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
					request.predicate = [NSPredicate predicateWithFormat:@"published == TRUE AND group.category.categoryID == 16"];
					request.resultType = NSDictionaryResultType;
					request.propertiesToFetch = @[entity.propertiesByName[@"typeID"]];
					for (NSDictionary* object in [database.backgroundManagedObjectContext executeFetchRequest:request error:nil]) {
						mSkills[object[@"typeID"]] = level;
					}
				}];
			}
			skills = mSkills;
			self.skills = skills;
		}
		
		return skills;
	}
}


@end
