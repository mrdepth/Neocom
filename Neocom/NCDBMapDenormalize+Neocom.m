//
//  NCDBMapDenormalize+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 19.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBMapDenormalize+Neocom.h"
#import "NCDatabase.h"

@implementation NCDBMapDenormalize (Neocom)

+ (instancetype) mapDenormalizeWithItemID:(int32_t) itemID {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"MapDenormalize"];
	request.predicate = [NSPredicate predicateWithFormat:@"itemID == %d", itemID];
	request.fetchLimit = 1;
	return [[database.managedObjectContext executeFetchRequest:request error:nil] lastObject];
}

@end