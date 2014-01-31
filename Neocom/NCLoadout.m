//
//  NCLoadout.m
//  Neocom
//
//  Created by Shimanski Artem on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCLoadout.h"
#import "NCLoadoutData.h"
#import "EVEDBAPI.h"
#import "NCStorage.h"

#define NCCategoryIDShip 6

@interface NCLoadout()

@end

@implementation NCLoadout
@synthesize type = _type;

@dynamic loadoutName;
@dynamic typeID;
@dynamic url;
@dynamic data;

+ (NSArray*) loadouts {
	NCStorage* storage = [NCStorage sharedStorage];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	return fetchedObjects;
}

+ (NSArray*) shipLoadouts {
	return [[self loadouts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category == %d", NCLoadoutCategoryShip]];
}

+ (NSArray*) posLoadouts {
	return [[self loadouts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category == %d", NCLoadoutCategoryPOS]];
}

- (EVEDBInvType*) type {
	if (!_type) {
		_type = [EVEDBInvType invTypeWithTypeID:self.typeID error:nil];
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
	return self.type.group.categoryID == NCCategoryIDShip ? NCLoadoutCategoryShip : NCLoadoutCategoryPOS;
}

@end
