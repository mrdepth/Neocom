//
//  PriceManager.m
//  EVEUniverse
//
//  Created by Mr. Depth on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PriceManager.h"
#import "EVEDBAPI.h"
#import "EVECentralAPI.h"

@interface PriceManager(Private)
@end

@implementation PriceManager

- (id) init {
	if (self = [super init]) {
		prices = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc {
	[prices release];
	[super dealloc];
}

- (float) priceWithType:(EVEDBInvType*) type {
	@synchronized(self) {
		NSString* key = [NSString stringWithFormat:@"%d", type.typeID];
		NSNumber* price = [prices valueForKey:key];
		if (!price) {
			EVECentralMarketStat* marketStat = [EVECentralMarketStat marketStatWithTypeIDs:[NSArray arrayWithObject:key] regionIDs:nil hours:0 minQ:0 error:nil];
			float price = 0;
			if (marketStat.types.count == 1)
				price = [[[marketStat.types objectAtIndex:0] sell] avg];
			else
				price = type.basePrice;
			[prices setValue:[NSNumber numberWithFloat:price] forKey:key];
			return price;
		}
		else
			return [price floatValue];
	}
}

- (NSDictionary*) pricesWithTypes:(NSArray*) types {
	NSMutableDictionary* result = [NSMutableDictionary dictionary];
	NSMutableArray* typeIDs = [NSMutableArray array];

	for (EVEDBInvType* type in types) {
		NSString* key = [NSString stringWithFormat:@"%d", type.typeID];
		NSNumber* price = [prices valueForKey:key];

		if (!price) {
			[typeIDs addObject:key];
			[result setValue:[NSNumber numberWithFloat:type.basePrice] forKey:key];
		}
		else
			[result setValue:price forKey:key];
	}
	if (typeIDs.count > 0) {
		EVECentralMarketStat* marketStat = [EVECentralMarketStat marketStatWithTypeIDs:typeIDs regionIDs:nil hours:0 minQ:0 error:nil];
		for (EVECentralMarketStatType* type in marketStat.types) {
			NSString* key = [NSString stringWithFormat:@"%d", type.typeID];
			[result setValue:[NSNumber numberWithFloat:type.sell.avg] forKey:key];
		}
	}
	return result;
}

@end
