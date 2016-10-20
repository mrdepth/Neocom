//
//  NCDBDgmEffect+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmEffect+CoreDataProperties.h"

@implementation NCDBDgmEffect (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmEffect *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmEffect"];
}

@dynamic effectID;
@dynamic types;

@end
