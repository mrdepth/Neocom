//
//  NCFitCharacter+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCFitCharacter+CoreDataProperties.h"

@implementation NCFitCharacter (CoreDataProperties)

+ (NSFetchRequest<NCFitCharacter *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"FitCharacter"];
}

@dynamic name;
@dynamic skills;

@end
