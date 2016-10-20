//
//  NCDBEveUnit+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBEveUnit+CoreDataProperties.h"

@implementation NCDBEveUnit (CoreDataProperties)

+ (NSFetchRequest<NCDBEveUnit *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EveUnit"];
}

@dynamic displayName;
@dynamic unitID;
@dynamic attributeTypes;

@end
