//
//  NCDBIndBlueprintType+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBIndBlueprintType+CoreDataProperties.h"

@implementation NCDBIndBlueprintType (CoreDataProperties)

+ (NSFetchRequest<NCDBIndBlueprintType *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"IndBlueprintType"];
}

@dynamic maxProductionLimit;
@dynamic activities;
@dynamic type;

@end
