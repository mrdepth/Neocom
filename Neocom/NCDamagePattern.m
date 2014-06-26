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
	NSManagedObjectContext* context = [NSThread isMainThread] ? self.managedObjectContext : self.backgroundManagedObjectContext;
	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"DamagePattern" inManagedObjectContext:context];
		[fetchRequest setEntity:entity];
		fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
		
		fetchedObjects = [context executeFetchRequest:fetchRequest error:nil];
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
