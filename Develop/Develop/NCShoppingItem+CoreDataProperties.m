//
//  NCShoppingItem+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCShoppingItem+CoreDataProperties.h"

@implementation NCShoppingItem (CoreDataProperties)

+ (NSFetchRequest<NCShoppingItem *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ShoppingItem"];
}

@dynamic finished;
@dynamic quantity;
@dynamic typeID;
@dynamic shoppingGroup;

@end
