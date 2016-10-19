//
//  NCImplantSet+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCImplantSet+CoreDataProperties.h"

@implementation NCImplantSet (CoreDataProperties)

+ (NSFetchRequest<NCImplantSet *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ImplantSet"];
}

@dynamic data;
@dynamic name;

@end
