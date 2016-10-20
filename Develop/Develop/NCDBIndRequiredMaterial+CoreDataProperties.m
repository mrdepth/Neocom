//
//  NCDBIndRequiredMaterial+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBIndRequiredMaterial+CoreDataProperties.h"

@implementation NCDBIndRequiredMaterial (CoreDataProperties)

+ (NSFetchRequest<NCDBIndRequiredMaterial *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"IndRequiredMaterial"];
}

@dynamic quantity;
@dynamic activity;
@dynamic materialType;

@end
