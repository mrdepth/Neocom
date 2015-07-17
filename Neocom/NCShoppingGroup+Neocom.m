//
//  NCShoppingGroup+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 01.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingGroup+Neocom.h"
#import "NCShoppingItem+Neocom.h"
#import "EVECentralAPI.h"

@implementation NCShoppingGroup (Neocom)

- (double) price {
	double price = 0;
	for (NCShoppingItem* item in self.shoppingItems)
		price += item.price * item.quantity;
	return price * self.quantity;
}

@end
