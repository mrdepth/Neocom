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

- (id) initWithTypeID:(int32_t) typeID quantity:(int32_t) quantity entity:(NSEntityDescription*) entity insertIntoManagedObjectContext:(NSManagedObjectContext*) context {
	if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
		self.typeID = typeID;
		self.quantity = quantity;
	}
	return self;
}

- (double) price {
	return [objc_getAssociatedObject(self, @"price") doubleValue];
}

- (void) setPrice:(double)price {
	objc_setAssociatedObject(self, @"price", @(price), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
