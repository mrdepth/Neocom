//
//  NCDBDgmAttributeType+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 12.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmAttributeType+Neocom.h"
#import "NCDatabase.h"

@implementation NCDBDgmAttributeType (Neocom)

+ (instancetype) dgmAttributeTypeWithAttributeTypeID:(int32_t) attributeTypeID {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DgmAttributeType"];
	request.predicate = [NSPredicate predicateWithFormat:@"attributeID == %d", attributeTypeID];
	request.fetchLimit = 1;
	return [[database.managedObjectContext executeFetchRequest:request error:nil] lastObject];
}

@end
