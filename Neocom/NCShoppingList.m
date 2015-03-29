//
//  NCShoppingList.m
//  Neocom
//
//  Created by Артем Шиманский on 27.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingList.h"
#import "NCShoppingItem.h"

static NCShoppingList* currentShoppingList;

@implementation NCStorage(NCShoppingList)

- (NSArray*) allShoppingLists {
	NSManagedObjectContext* context = [NSThread isMainThread] ? self.managedObjectContext : self.backgroundManagedObjectContext;
	
	__block NSArray* shoppingLists = nil;
	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ShoppingList"];
		[fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
		
		shoppingLists = [context executeFetchRequest:fetchRequest error:nil];
	}];
	return shoppingLists;
}

@end


@implementation NCShoppingList

@dynamic name;
@dynamic items;

+ (instancetype) currentShoppingList {
	@synchronized(self) {
		if (!currentShoppingList) {
			NSString* urlString = [[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsCurrentShoppingListKey];
			NCStorage* storage = [NCStorage sharedStorage];
			NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;

			if (urlString && context) {
				NSURL* url = [NSURL URLWithString:urlString];
				if (url) {
					[context performBlockAndWait:^{
						NSManagedObjectID* managedObjectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
						if (managedObjectID)
							currentShoppingList = (NCShoppingList*) [context existingObjectWithID:managedObjectID error:nil];
					}];
				}
			}
			if (!currentShoppingList && context) {
				[context performBlockAndWait:^{
					NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"ShoppingList"];
					request.fetchLimit = 1;
					currentShoppingList = [[context executeFetchRequest:request error:nil] lastObject];
					if (!currentShoppingList) {
						currentShoppingList = [[NCShoppingList alloc] initWithEntity:[NSEntityDescription entityForName:@"ShoppingList" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
						currentShoppingList.name = NSLocalizedString(@"Default", nil);
						[context save:nil];
					}
				}];
			}
		}
		return currentShoppingList;
	}
}

+ (void) setCurrentShoppingList:(NCShoppingList*) shoppingList {
	@synchronized(self) {
		if (currentShoppingList != shoppingList) {
			currentShoppingList = shoppingList;
			if (shoppingList)
				[[NSUserDefaults standardUserDefaults] setValue:[shoppingList.objectID.URIRepresentation absoluteString] forKey:NCSettingsCurrentShoppingListKey];
			else
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:NCSettingsCurrentShoppingListKey];
			//[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}
}

@end
