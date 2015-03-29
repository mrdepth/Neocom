//
//  NCPriceManager.m
//  Neocom
//
//  Created by Артем Шиманский on 03.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCPriceManager.h"
#import "NCCache.h"

@interface NCPriceManagerDataRecord : NSObject<NSCoding>
@property (nonatomic, strong) EVECentralMarketStatType* marketStat;
@property (nonatomic, strong) NSDate* date;
@end

@interface NCPriceManagerData : NSObject<NSCoding>
@property (nonatomic, strong) NSDictionary* marketStat;
@end

@implementation NCPriceManagerDataRecord

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.marketStat = [aDecoder decodeObjectForKey:@"marketStat"];
		self.date = [aDecoder decodeObjectForKey:@"date"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.marketStat)
		[aCoder encodeObject:self.marketStat forKey:@"marketStat"];
	if (self.date)
		[aCoder encodeObject:self.date forKey:@"date"];
}

@end

@implementation NCPriceManagerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.marketStat = [aDecoder decodeObjectForKey:@"marketStat"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.marketStat)
		[aCoder encodeObject:self.marketStat forKey:@"marketStat"];
}

@end

@interface NCPriceManager()
@property (nonatomic, strong) NCCacheRecord* cacheRecord;
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

- (EVECentralMarketStatType*) priceWithType:(NSInteger) typeID {
	return [self pricesWithTypes:@[@(typeID)]][@(typeID)];
}

- (NSDictionary*) pricesWithTypes:(NSArray*) types {
	@synchronized(self) {
		NCPriceManagerData* data = self.cacheRecord.data.data;
		NSMutableArray* missingTypes = [types mutableCopy];
		NSMutableDictionary* prices = [NSMutableDictionary new];
		
		for (NSNumber* typeID in types) {
			NCPriceManagerDataRecord* record = data.marketStat[typeID];
			if (record)
				prices[typeID] = record.marketStat;
			
			if (record && [record.date timeIntervalSinceNow] > -3600 * 24)
				[missingTypes removeObject:typeID];
		}
		if (missingTypes.count > 0 && ![NSThread isMainThread]) {
			NSMutableDictionary* records = [NSMutableDictionary new];
			[data.marketStat enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NCPriceManagerDataRecord* obj, BOOL *stop) {
				if ([obj.date timeIntervalSinceNow] > -3600 * 24 * 7)
					records[key] = obj;
			}];

			EVECentralMarketStat* marketStat = [EVECentralMarketStat marketStatWithTypeIDs:missingTypes regionIDs:nil hours:0 minQ:0 cachePolicy:NSURLRequestUseProtocolCachePolicy error:nil progressHandler:nil];
			NSDate* date = [NSDate date];
			for (EVECentralMarketStatType* stat in marketStat.types) {
				prices[@(stat.typeID)] = stat;
				NCPriceManagerDataRecord* record = [NCPriceManagerDataRecord new];
				record.marketStat = stat;
				record.date = date;
				records[@(stat.typeID)] = record;
			}
			
			NCPriceManagerData* newData = [NCPriceManagerData new];
			newData.marketStat = records;
			NCCache* cache = [NCCache sharedCache];
			[cache.managedObjectContext performBlockAndWait:^{
				self.cacheRecord.data.data = newData;
				[cache saveContext];
			}];
		}
		
		return prices;
	}
	return nil;
}

#pragma mark - Private

- (NCCacheRecord*) cacheRecord {
	@synchronized(self) {
		if (!_cacheRecord) {
			NCCache* cache = [NCCache sharedCache];
			[cache.managedObjectContext performBlockAndWait:^{
				_cacheRecord = [NCCacheRecord cacheRecordWithRecordID:@"NCPriceManager"];
			}];
		}
		return _cacheRecord;
	}
}

@end
