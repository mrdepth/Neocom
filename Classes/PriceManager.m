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

@implementation PriceManager
@synthesize faction;

- (id) init {
	if (self = [super init]) {
		prices = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc {
	[prices release];
	[faction release];
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
			else {
				EVEC0rporationFactionItem* item = [self.faction.types valueForKey:key];
				if (item)
					price = item.avg;
				else
					price = type.basePrice;
			}
			[prices setValue:[NSNumber numberWithFloat:price] forKey:key];
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
			NSString* key = [NSString stringWithFormat:@"%d", type.typeID];
			NSNumber* price = [prices valueForKey:key];
			
			if (!price) {
				[typeIDs addObject:key];
				[result setValue:[NSNull null] forKey:key];
			}
			else
				[result setValue:price forKey:key];
		}
		if (typeIDs.count > 0) {
			EVECentralMarketStat* marketStat = [EVECentralMarketStat marketStatWithTypeIDs:typeIDs regionIDs:nil hours:0 minQ:0 error:nil];
			for (EVECentralMarketStatType* type in marketStat.types) {
				NSString* key = [NSString stringWithFormat:@"%d", type.typeID];
				if (type.sell.avg > 0) {
					NSNumber* value = [NSNumber numberWithFloat:type.sell.median];
					[result setValue:value forKey:key];
					[prices setValue:value forKey:key];
				}
			}
			for (EVEDBInvType* type in types) {
				NSString* key = [NSString stringWithFormat:@"%d", type.typeID];
				if ([result valueForKey:key] == [NSNull null]) {
					EVEC0rporationFactionItem* item = [self.faction.types valueForKey:key];
					if (item) {
						NSNumber* value = [NSNumber numberWithFloat:item.median];
						[result setValue:value forKey:key];
						[prices setValue:value forKey:key];
					}
					else {
						NSNumber* value = [NSNumber numberWithFloat:type.basePrice];
						[result setValue:value forKey:key];
						[prices setValue:value forKey:key];
					}
				}
			}
		}
		return result;
	}
}

- (EVEC0rporationFaction*) faction {
	@synchronized(self) {
		if (!faction) {
			faction = [[EVEC0rporationFaction factionWithError:nil] retain];
		}
		return faction;
	}
}

@end
