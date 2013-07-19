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
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:storage.managedObjectContext]];
	return [storage.managedObjectContext executeFetchRequest:fetchRequest error:nil];
}

@end
