//
//  NCPOSFit.m
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCPOSFit.h"
#import "NCStorage.h"

@implementation NCPOSFit

@dynamic structures;

+ (NSArray*) allFits {
	NCStorage* storage = [NCStorage sharedStorage];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"POSFit" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	return fetchedObjects;
}

@end
