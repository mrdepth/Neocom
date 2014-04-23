//
//  NCDamagePattern.m
//  Neocom
//
//  Created by Артем Шиманский on 04.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDamagePattern.h"

@implementation NCStorage(NCDamagePattern)

- (NSArray*) damagePatterns {
	__block NSArray *fetchedObjects = nil;
	[self.managedObjectContext performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"DamagePattern" inManagedObjectContext:self.managedObjectContext];
		[fetchRequest setEntity:entity];
		fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
		
		fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
	}];
	return fetchedObjects;
}

@end

@implementation NCDamagePattern

@dynamic em;
@dynamic thermal;
@dynamic kinetic;
@dynamic explosive;
@dynamic name;

@end
