//
//  NCCacheRecord+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCacheRecord+CoreDataProperties.h"

@implementation NCCacheRecord (CoreDataProperties)

+ (NSFetchRequest<NCCacheRecord *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Record"];
}

@dynamic date;
@dynamic expireDate;
@dynamic recordID;
@dynamic data;

@end
