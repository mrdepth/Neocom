//
//  NCLoadoutData+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCLoadoutData+CoreDataProperties.h"

@implementation NCLoadoutData (CoreDataProperties)

+ (NSFetchRequest<NCLoadoutData *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"LoadoutData"];
}

@dynamic data;
@dynamic loadout;

@end
