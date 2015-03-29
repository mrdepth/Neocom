//
//  NCShoppingItem+Neocom.m
//  Neocom
//
//  Created by Artem Shimanski on 29.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingItem+Neocom.h"
#import "NCDatabase.h"
#import "NCStorage.h"
#import <objc/runtime.h>

@implementation NCShoppingItem (Neocom)

+ (instancetype) shoppingItemWithType:(NCDBInvType*) type quantity:(int32_t) quantity {
	if (!type)
		return nil;
	
	NSManagedObjectContext* context = [[NCStorage sharedStorage] managedObjectContext];
	NCShoppingItem* item = [[NCShoppingItem alloc] initWithEntity:[NSEntityDescription entityForName:@"ShoppingItem" inManagedObjectContext:context] insertIntoManagedObjectContext:nil];
	item.type = type;
	item.typeID = type.typeID;
	item.quantity = quantity;
	return item;
}

- (NCDBInvType*) type {
	NCDBInvType* type = objc_getAssociatedObject(self, @"type");
	if (!type) {
		type = [NCDBInvType invTypeWithTypeID:self.typeID];
		self.type = type;
	}
	return type;
}

- (void) setType:(NCDBInvType *)type {
	objc_setAssociatedObject(self, @"type", type, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EVECentralMarketStatType*) price {
	return objc_getAssociatedObject(self, @"price");
}

- (void) setPrice:(EVECentralMarketStatType *)price {
	objc_setAssociatedObject(self, @"price", price, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
