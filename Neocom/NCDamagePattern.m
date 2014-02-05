//
//  NCDamagePattern.m
//  Neocom
//
//  Created by Артем Шиманский on 04.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDamagePattern.h"
#import "NCStorage.h"

@implementation NCDamagePattern

@dynamic em;
@dynamic thermal;
@dynamic kinetic;
@dynamic explosive;
@dynamic name;

+ (NSArray*) damagePatterns {
	NCStorage* storage = [NCStorage sharedStorage];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"DamagePattern" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	return fetchedObjects;
}

@end
