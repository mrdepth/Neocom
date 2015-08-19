//
//  NCDBEufeItemCategory+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 18.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBEufeItemCategory+Neocom.h"
#import "NCDatabase.h"
#import <eufe/eufe.h>


@implementation NCDBEufeItemCategory (Neocom)

+ (id) shipsCategory {
	return [self categoryWithSlot:NCDBEufeItemSlotShip size:0 race:nil];
}

+ (id) controlTowersCategory {
	return [self categoryWithSlot:NCDBEufeItemSlotControlTower size:0 race:nil];
}

+ (id) categoryWithSlot:(NCDBEufeItemSlot) slot size:(int32_t) size race:(NCDBChrRace*) race {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EufeItemCategory"];
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"category == %d", (int32_t) slot, size];
	if (size)
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"subcategory == %d", size]]];
	if (race)
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"race == %@", race]]];
	request.predicate = predicate;
	request.fetchLimit = 1;
	return [[database.managedObjectContext executeFetchRequest:request error:nil] lastObject];
}

@end
