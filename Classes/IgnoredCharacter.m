//
//  IgnoredCharacter.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import "IgnoredCharacter.h"
#import "EUStorage.h"


@implementation IgnoredCharacter

@dynamic characterID;

+ (NSArray*) allIgnoredCharacters {
	EUStorage* storage = [EUStorage sharedStorage];
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"IgnoredCharacter" inManagedObjectContext:storage.managedObjectContext]];
	return [storage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
}

+ (IgnoredCharacter*) ignoredCharacterWithID:(NSInteger*) characterID {
	EUStorage* storage = [EUStorage sharedStorage];
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"IgnoredCharacter" inManagedObjectContext:storage.managedObjectContext]];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"characterID == %d", characterID];
	NSArray* results = [storage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	if (results.count > 0)
		return results[0];
	else
		return nil;
}

@end
