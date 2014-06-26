//
//  NCSetting.m
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCSetting.h"

@implementation NCStorage(NCSetting)

- (NCSetting*) settingWithKey:(NSString*) key {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	NCStorage* storage = [NCStorage sharedStorage];
	NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;

	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Setting" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]];
	
	NCSetting* setting = nil;
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:nil];
	if (fetchedObjects.count > 0)
		setting = fetchedObjects[0];
	if (!setting) {
		setting = [[NCSetting alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
		setting.key = key;
	}
	return setting;
}

@end

@implementation NCSetting

@dynamic key;
@dynamic value;



@end
