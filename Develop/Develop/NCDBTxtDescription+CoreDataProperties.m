//
//  NCDBTxtDescription+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBTxtDescription+CoreDataProperties.h"

@implementation NCDBTxtDescription (CoreDataProperties)

+ (NSFetchRequest<NCDBTxtDescription *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"TxtDescription"];
}

@dynamic text;
@dynamic certificate;
@dynamic type;

@end
