//
//  NCCachePrice+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCachePrice+CoreDataProperties.h"

@implementation NCCachePrice (CoreDataProperties)

+ (NSFetchRequest<NCCachePrice *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Price"];
}

@dynamic price;
@dynamic typeID;

@end
