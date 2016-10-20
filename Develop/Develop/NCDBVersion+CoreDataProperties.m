//
//  NCDBVersion+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBVersion+CoreDataProperties.h"

@implementation NCDBVersion (CoreDataProperties)

+ (NSFetchRequest<NCDBVersion *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Version"];
}

@dynamic build;
@dynamic expansion;
@dynamic version;

@end
