//
//  NCDBEufeItemCategory+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 18.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBEufeItemCategory+Neocom.h"
#import "NCDatabase.h"
#import "eufe.h"

typedef enum {
	SLOT_NONE = eufe::Module::SLOT_NONE,
	SLOT_HI,
	SLOT_MED,
	SLOT_LOW,
	SLOT_RIG,
	SLOT_SUBSYSTEM,
	SLOT_STRUCTURE,
	SLOT_CHARGE,
	SLOT_DRONE,
	SLOT_IMPLANT,
	SLOT_BOOSTER,
	SLOT_SHIP,
	SLOT_CONTROL_TOWER
} NCDBEufeItemSlot;

@interface NCDBEufeItemCategory(Private)

+ (id) categoryWithSlot:(NCDBEufeItemSlot) slot size:(int32_t) size race:(NCDBChrRace*) race;

@end

@implementation NCDBEufeItemCategory (Neocom)

+ (id) shipsCategory {
	return [self categoryWithSlot:SLOT_SHIP size:0 race:nil];
}

#pragma mark - Private

+ (id) categoryWithSlot:(NCDBEufeItemSlot) slot size:(int32_t) size race:(NCDBChrRace*) race {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EufeItemCategory"];
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"slot == %d", (int32_t) slot];
	if (size)
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"size == %d", size]]];
	if (race)
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"race == %@", race]]];
	request.predicate = predicate;
	request.fetchLimit = 1;
	__block NSArray* result;
	if ([NSThread isMainThread])
		result = [database.managedObjectContext executeFetchRequest:request error:nil];
	else
		[database.backgroundManagedObjectContext performBlockAndWait:^{
			result = [database.backgroundManagedObjectContext executeFetchRequest:request error:nil];
		}];
	return result.count > 0 ? result[0] : nil;
}

@end
