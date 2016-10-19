//
//  NCShoppingList+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCShoppingList+CoreDataProperties.h"

@implementation NCShoppingList (CoreDataProperties)

+ (NSFetchRequest<NCShoppingList *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ShoppingList"];
}

@dynamic name;
@dynamic shoppingGroups;

@end
