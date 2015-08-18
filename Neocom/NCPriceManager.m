//
//  NCPriceManager.m
//  Neocom
//
//  Created by Артем Шиманский on 03.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCPriceManager.h"
#import "NCCache.h"
#import "ASURLConnection.h"


@interface NCPriceManager()
@property (atomic, assign) BOOL updating;
@end

@implementation NCPriceManager

+ (instancetype) sharedManager {
	static NCPriceManager* sharedManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManager = [NCPriceManager new];
	});
	return sharedManager;
}

- (id) init {
	if (self = [super init]) {
		[self updateIfNeeded];
	}
	return self;
}

- (EVECentralMarketStatType*) priceWithType:(NSInteger) typeID {
	return [self pricesWithTypes:@[@(typeID)]][@(typeID)];
}

- (NSDictionary*) pricesWithTypes:(NSArray*) types {
	NCCache* cache = [NCCache sharedCache];
	NSMutableDictionary* prices = [NSMutableDictionary new];
	[cache.managedObjectContext performBlockAndWait:^{
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Price"];
		request.predicate = [NSPredicate predicateWithFormat:@"typeID in %@", types];
		for (NCCachePrice* price in [cache.managedObjectContext executeFetchRequest:request error:nil])
			prices[@(price.typeID)] = @(price.price);
	}];
	return prices;
}

- (void) updateIfNeeded {
	if (self.updating)
		return;
	
	self.updating = YES;
	NCCache* cache = [NCCache sharedCache];
	[cache.managedObjectContext performBlock:^{
		NCCacheRecord* cacheRecord = [NCCacheRecord cacheRecordWithRecordID:@"NCPriceManager"];
		NSDate* date = cacheRecord.expireDate;
		if (!date || [date timeIntervalSinceNow] < 0) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				@autoreleasepool {
					NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://public-crest.eveonline.com/market/prices/"]];
					[request setValue:@"application/vnd.ccp.eve.Api-v1+json" forHTTPHeaderField:@"Accept"];
					NSData* data = [ASURLConnection sendSynchronousRequest:request returningResponse:nil error:nil progressHandler:nil];
					if (data) {
						NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
						if ([dic isKindOfClass:[NSDictionary class]]) {
							[cache.managedObjectContext performBlock:^{
								NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Price"];
								for (NCCachePrice* record in [cache.managedObjectContext executeFetchRequest:request error:nil])
									[cache.managedObjectContext deleteObject:record];

								for (NSDictionary* item in dic[@"items"]) {
									int32_t typeID = [item[@"type"][@"id"] intValue];
									NCCachePrice* record = [NSEntityDescription insertNewObjectForEntityForName:@"Price" inManagedObjectContext:cache.managedObjectContext];
									record.typeID = typeID;
									double adjustedPrice = [item[@"adjustedPrice"] doubleValue];
									double averagePrice = [item[@"averagePrice"] doubleValue];
									record.price = averagePrice > 0 ? averagePrice : adjustedPrice;
								}
								cacheRecord.date = [NSDate date];
								cacheRecord.expireDate = [NSDate dateWithTimeIntervalSinceNow:3600 * 24];
								if ([cache.managedObjectContext hasChanges])
									[cache.managedObjectContext save:nil];
								self.updating = NO;
							}];
						}
						else
							self.updating = NO;
					}
					else
						self.updating = NO;
				}
			});
		}
		else
			self.updating = NO;
	}];
}

@end
