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
#import "EVEC0rporationAPI.h"

@interface PriceManager()
@property (nonatomic, strong) NSMutableDictionary* prices;

@end

@implementation PriceManager

- (id) init {
	if (self = [super init]) {
		self.prices = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (float) priceWithType:(EVEDBInvType*) type {
	@synchronized(self) {
		NSString* key = [NSString stringWithFormat:@"%d", type.typeID];
		NSNumber* price = [self.prices valueForKey:key];
		if (!price) {
			EVECentralMarketStat* marketStat = [EVECentralMarketStat marketStatWithTypeIDs:[NSArray arrayWithObject:key] regionIDs:nil hours:0 minQ:0 error:nil progressHandler:nil];
			float price = 0;
			if (marketStat.types.count == 1)
				price = [[[marketStat.types objectAtIndex:0] sell] avg];
			else {
				EVEC0rporationFactionItem* item = [self.faction.types valueForKey:key];
				if (item)
					price = item.avg;
				else
					price = type.basePrice;
			}
			[self.prices setValue:[NSNumber numberWithFloat:price] forKey:key];
			return price;
		}
		else
			return [price floatValue];
	}
}

- (NSDictionary*) pricesWithTypes:(NSArray*) types {
	@synchronized(self) {
		NSMutableDictionary* result = [NSMutableDictionary dictionary];
		NSMutableArray* typeIDs = [NSMutableArray array];
		for (EVEDBInvType* type in types) {
			NSNumber* key = @(type.typeID);
			NSNumber* price = self.prices[key];
			
			if (!price) {
				[typeIDs addObject:key];
				result[key] = [NSNull null];
			}
			else
				result[key] = price;
		}
		if (typeIDs.count > 0) {
			EVECentralMarketStat* marketStat = [EVECentralMarketStat marketStatWithTypeIDs:typeIDs regionIDs:nil hours:0 minQ:0 error:nil progressHandler:nil];
			for (EVECentralMarketStatType* type in marketStat.types) {
				NSNumber* key = @(type.typeID);
				if (type.sell.avg > 0) {
					NSNumber* value = @(type.sell.median);
					result[key] = value;
					self.prices[key] = value;
				}
			}
			for (EVEDBInvType* type in types) {
				NSNumber* key = @(type.typeID);
				if (result[key] == [NSNull null]) {
					EVEC0rporationFactionItem* item = self.faction.types[key];
					if (item) {
						NSNumber* value = @(item.median);
						result[key] = value;
						self.prices[key] = value;
					}
					else {
						NSNumber* value = @(type.basePrice);
						result[key] = value;
						self.prices[key] = value;
					}
				}
			}
		}
		return result;
	}
}

- (EVEC0rporationFaction*) faction {
	@synchronized(self) {
		if (!_faction) {
			_faction = [EVEC0rporationFaction factionWithError:nil progressHandler:nil];
		}
		return _faction;
	}
}

@end
