//
//  NCDBDgmAttributeType+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmAttributeType+CoreDataProperties.h"

@implementation NCDBDgmAttributeType (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmAttributeType *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmAttributeType"];
}

@dynamic attributeID;
@dynamic attributeName;
@dynamic displayName;
@dynamic published;
@dynamic attributeCategory;
@dynamic icon;
@dynamic typeAttributes;
@dynamic unit;

@end
