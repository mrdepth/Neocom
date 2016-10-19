//
//  NCSetting+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSetting+CoreDataProperties.h"

@implementation NCSetting (CoreDataProperties)

+ (NSFetchRequest<NCSetting *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Setting"];
}

@dynamic key;
@dynamic value;

@end
