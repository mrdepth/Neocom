//
//  NCDBIndActivity+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBIndActivity+CoreDataProperties.h"

@implementation NCDBIndActivity (CoreDataProperties)

+ (NSFetchRequest<NCDBIndActivity *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"IndActivity"];
}

@dynamic time;
@dynamic activity;
@dynamic blueprintType;
@dynamic products;
@dynamic requiredMaterials;
@dynamic requiredSkills;

@end
