//
//  NCDBEveIconImage+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBEveIconImage+CoreDataProperties.h"

@implementation NCDBEveIconImage (CoreDataProperties)

+ (NSFetchRequest<NCDBEveIconImage *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EveIconImage"];
}

@dynamic image;
@dynamic icon;

@end
