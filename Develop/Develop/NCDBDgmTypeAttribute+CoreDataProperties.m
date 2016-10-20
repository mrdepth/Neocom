//
//  NCDBDgmTypeAttribute+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmTypeAttribute+CoreDataProperties.h"

@implementation NCDBDgmTypeAttribute (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmTypeAttribute *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmTypeAttribute"];
}

@dynamic value;
@dynamic attributeType;
@dynamic type;

@end
