//
//  NCShoppingList.m
//  Neocom
//
//  Created by Артем Шиманский on 01.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingList.h"
#import "NCShoppingItem.h"


static NCShoppingList* currentShoppingList;

@implementation NCShoppingList

@dynamic name;
@dynamic shoppingGroups;

+ (void) setCurrentShoppingList:(NCShoppingList*) shoppingList {
	if (shoppingList)
		[[NSUserDefaults standardUserDefaults] setValue:[shoppingList.objectID.URIRepresentation absoluteString] forKey:NCSettingsCurrentShoppingListKey];
	else
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:NCSettingsCurrentShoppingListKey];
}

@end
