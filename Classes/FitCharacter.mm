//
//  FitCharacter.m
//  EVEUniverse
//
//  Created by mr_depth on 08.08.13.
//
//

#import "FitCharacter.h"
#import "EUStorage.h"
#import "EVEAccount.h"

@interface FitCharacter()
@end

@implementation FitCharacter

@dynamic name;
@dynamic skills;
@dynamic type;

@synthesize skillsDictionary = _skillsDictionary;
@synthesize account = _account;

+ (NSArray*) allCustomCharacters {
	EUStorage* storage = [EUStorage sharedStorage];
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:storage.managedObjectContext]];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"type == %d", FitCharacterTypeCustom];
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	return [storage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
}

+ (FitCharacter*) fitCharacterWithAccount:(EVEAccount*) account {
	EUStorage* storage = [EUStorage sharedStorage];
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"FitCharacter" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@ AND type == %d", account.character.characterName, FitCharacterTypeAccount];
	NSArray* result = [storage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	
	FitCharacter* fitCharacter;
	if (result.count > 0)
		fitCharacter = result[0];
	else {
		fitCharacter = [[FitCharacter alloc] initWithEntity:entity insertIntoManagedObjectContext:storage.managedObjectContext];
		fitCharacter.type = FitCharacterTypeAccount;
	}
	if (account.character.characterName && ![account.character.characterName isEqualToString:fitCharacter.name])
		fitCharacter.name = account.character.characterName;
	fitCharacter.account = account;
	return fitCharacter;
}


- (NSMutableDictionary*) skillsDictionary {
	if (!_skillsDictionary) {
		_skillsDictionary = [NSMutableDictionary new];
		if (self.account.characterSheet) {
			for (EVECharacterSheetSkill* skill in self.account.characterSheet.skills)
				_skillsDictionary[@(skill.typeID)] = @(skill.level);
		}
		else {
			for (NSString* component in [self.skills componentsSeparatedByString:@";"]) {
				NSArray* subComponents = [component componentsSeparatedByString:@":"];
				if (subComponents.count == 2)
					_skillsDictionary[@([subComponents[0] integerValue])] = @([subComponents[1] integerValue]);
			}
		}
	}
	return _skillsDictionary;
}

- (BOOL) isReadonly {
	return self.type == FitCharacterTypeAccount;
}

- (boost::shared_ptr<std::map<eufe::TypeID, int> >) skillsMap {
	boost::shared_ptr<std::map<eufe::TypeID, int> > levels(new std::map<eufe::TypeID, int>);
	[self.skillsDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NSNumber* level, BOOL *stop) {
		(*levels)[static_cast<eufe::TypeID>([key intValue])] = [level intValue];
	}];
	return levels;
}

- (void) save {
	NSMutableArray* components = [NSMutableArray new];
	[self.skillsDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NSNumber* level, BOOL *stop) {
		[components addObject:[NSString stringWithFormat:@"%@:%@", key, level]];
	}];
	[components sortUsingSelector:@selector(compare:)];
	NSString* skills = [components componentsJoinedByString:@";"];
	if (![self.skills isEqualToString:skills])
		self.skills = skills;
	[[EUStorage sharedStorage] saveContext];
}

@end
