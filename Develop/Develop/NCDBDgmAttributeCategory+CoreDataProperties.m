//
//  NCDBDgmAttributeCategory+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmAttributeCategory+CoreDataProperties.h"

@implementation NCDBDgmAttributeCategory (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmAttributeCategory *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmAttributeCategory"];
}

@dynamic categoryID;
@dynamic categoryName;
@dynamic attributeTypes;

@end
