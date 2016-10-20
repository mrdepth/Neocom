//
//  NCDBIndProduct+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBIndProduct+CoreDataProperties.h"

@implementation NCDBIndProduct (CoreDataProperties)

+ (NSFetchRequest<NCDBIndProduct *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"IndProduct"];
}

@dynamic probability;
@dynamic quantity;
@dynamic activity;
@dynamic productType;

@end
