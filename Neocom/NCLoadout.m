//
//  NCLoadout.m
//  Neocom
//
//  Created by Shimanski Artem on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCLoadout.h"
#import "NCLoadoutData.h"
#import "NCStorage.h"
#import "NCDatabase.h"

#define NCCategoryIDShip 6

@implementation NCStorage(NCLoadout)

- (NSArray*) loadouts {
	NSMutableArray* loadouts = [NSMutableArray new];
	NSManagedObjectContext* context = [NSThread isMainThread] ? self.managedObjectContext : self.backgroundManagedObjectContext;
	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:context];
		[fetchRequest setEntity:entity];
		
		NSError *error = nil;
		NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
		for (NCLoadout* loadout in fetchedObjects) {
			if (!loadout.typeID)
				[context deleteObject:loadout];
			else
				[loadouts addObject:loadout];
		}
		if ([context hasChanges])
			[context save:nil];
	}];
	return loadouts;
}

- (NSArray*) shipLoadouts {
	return [[self loadouts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category == %d", NCLoadoutCategoryShip]];
}

- (NSArray*) posLoadouts {
	return [[self loadouts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category == %d", NCLoadoutCategoryPOS]];
}


@end

@implementation NCLoadout
@synthesize type = _type;

@dynamic name;
@dynamic typeID;
@dynamic url;
@dynamic data;

- (NCDBInvType*) type {
	if (!_type) {
		_type = [NCDBInvType invTypeWithTypeID:self.typeID];
	}
	return _type;
}

- (void) setTypeID:(int32_t)typeID {
	[self willChangeValueForKey:@"typeID"];
	[self setPrimitiveValue:@(typeID) forKey:@"typeID"];
	_type = nil;
	[self didChangeValueForKey:@"typeID"];
}

- (NCLoadoutCategory) category {
	return self.type.group.category.categoryID == NCCategoryIDShip ? NCLoadoutCategoryShip : NCLoadoutCategoryPOS;
}

@end
