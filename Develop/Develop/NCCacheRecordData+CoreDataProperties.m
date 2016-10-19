//
//  NCCacheRecordData+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCacheRecordData+CoreDataProperties.h"

@implementation NCCacheRecordData (CoreDataProperties)

+ (NSFetchRequest<NCCacheRecordData *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RecordData"];
}

@dynamic data;
@dynamic record;

@end
