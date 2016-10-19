//
//  NCShoppingGroup+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCShoppingGroup+CoreDataProperties.h"

@implementation NCShoppingGroup (CoreDataProperties)

+ (NSFetchRequest<NCShoppingGroup *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ShoppingGroup"];
}

@dynamic iconFile;
@dynamic identifier;
@dynamic immutable;
@dynamic name;
@dynamic quantity;
@dynamic shoppingItems;
@dynamic shoppingList;

@end
