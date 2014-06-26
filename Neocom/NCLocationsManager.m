//
//  NCLocationsManager.m
//  Neocom
//
//  Created by Артем Шиманский on 17.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCLocationsManager.h"
#import "NCCache.h"
#import "EVEOnlineAPI.h"
#import "NCDatabase.h"

@implementation NCLocationsManagerItem

- (id) initWithName:(NSString*) name solarSystem:(NCDBMapSolarSystem*) solarSystem {
	if (self = [super init]) {
		self.name = name;
		self.solarSystem = solarSystem;
	}
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.name = [aDecoder decodeObjectForKey:@"name"];
		int32_t solarSystemID = [aDecoder decodeInt32ForKey:@"solarSystemID"];
		if (solarSystemID)
			self.solarSystem = [NCDBMapSolarSystem mapSolarSystemWithSolarSystemID:solarSystemID];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.name)
		[aCoder encodeObject:self.name forKey:@"name"];
	if (self.solarSystem)
		[aCoder encodeInt32:self.solarSystem.solarSystemID forKey:@"solarSystemID"];
}

@end


@interface NCLocationsManager()
@property (nonatomic, strong) NCCacheRecord* cacheRecord;
@property (nonatomic, strong) NCCacheRecord* conquerableStationsRecord;
@property (nonatomic, strong) NSMutableDictionary* locationsNames;
@property (nonatomic, strong) NSDictionary* conquerableStations;
- (void) didReceiveMemoryWarning;
@end

@implementation NCLocationsManager

+ (instancetype) defaultManager {
	@synchronized(self) {
		static NCLocationsManager* defaultManager = nil;
		if (!defaultManager)
			defaultManager = [NCLocationsManager new];
		return defaultManager;
	}
}

- (id) init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSDictionary*) locationsNamesWithIDs:(NSArray*) ids {
	@synchronized(self) {
		NSMutableArray* missingIDs = [ids mutableCopy];
		NSMutableDictionary* locationsNames = self.locationsNames;
		NSMutableDictionary* results = [NSMutableDictionary new];
		
		for (NSNumber* locationID in ids) {
			int32_t locationIDl = [locationID intValue];
			
			NCLocationsManagerItem* name = locationsNames[locationID];
			if (!name) {
				
				if (66000000 < locationIDl && locationIDl < 66014933) { //staStations
					int32_t locationID = locationIDl - 6000001;
					NCDBStaStation *station = [NCDBStaStation staStationWithStationID:locationID];
					if (station)
						name = [[NCLocationsManagerItem alloc] initWithName:station.stationName solarSystem:station.solarSystem];
				}
				else if (66014934 < locationIDl && locationIDl < 67999999) { //staStations
					int32_t locationID = locationIDl - 6000000;
					EVEConquerableStationListItem *conquerableStation = self.conquerableStations[@(locationID)];
					if (conquerableStation) {
						NCDBMapSolarSystem *solarSystem = [NCDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID];
						name = [[NCLocationsManagerItem alloc] initWithName:conquerableStation.stationName solarSystem:solarSystem];
					}
				}
				else if (60014861 < locationIDl && locationIDl < 60014928) { //ConqStations
					EVEConquerableStationListItem *conquerableStation = self.conquerableStations[@(locationIDl)];
					if (conquerableStation) {
						NCDBMapSolarSystem *solarSystem = [NCDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID];
						name = [[NCLocationsManagerItem alloc] initWithName:conquerableStation.stationName solarSystem:solarSystem];
					}
				}
				else if (60000000 < locationIDl && locationIDl < 61000000) { //staStations
					NCDBStaStation *station = [NCDBStaStation staStationWithStationID:locationIDl];
					name = [[NCLocationsManagerItem alloc] initWithName:station.stationName solarSystem:station.solarSystem];
				}
				else if (61000000 <= locationIDl) { //ConqStations
					EVEConquerableStationListItem *conquerableStation = self.conquerableStations[@(locationIDl)];
					if (conquerableStation) {
						NCDBMapSolarSystem *solarSystem = [NCDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID];
						name = [[NCLocationsManagerItem alloc] initWithName:conquerableStation.stationName solarSystem:solarSystem];
					}
				}
				else { //mapDenormalize
					NCDBMapDenormalize *denormalize = [NCDBMapDenormalize mapDenormalizeWithItemID:locationIDl];
					if (denormalize) {
						name = [[NCLocationsManagerItem alloc] initWithName:denormalize.itemName solarSystem:denormalize.solarSystem];
					}
				}
			}
			
			if (name) {
				results[locationID] = name;
				[missingIDs removeObject:locationID];
			}
		}
		if (![NSThread isMainThread]) {
			EVECharacterName* characterName = [EVECharacterName characterNameWithIDs:missingIDs cachePolicy:NSURLRequestUseProtocolCachePolicy error:nil progressHandler:nil];
			if (characterName.characters.count > 0) {
				[characterName.characters enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NSString* obj, BOOL *stop) {
					NCLocationsManagerItem* name = [[NCLocationsManagerItem alloc] initWithName:obj solarSystem:nil];
					results[key] = name;
					locationsNames[key] = name;
				}];
				NCCacheRecord* cacheRecord = self.cacheRecord;

				[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
					cacheRecord.data.data = locationsNames;
					if ([cacheRecord.expireDate isEqualToDate:[NSDate distantPast]]) {
						cacheRecord.date = [NSDate date];
						cacheRecord.expireDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 7];
					}
					[[NCCache sharedCache] saveContext];
				}];
			}
		}
		return results;
	}
}

#pragma mark - Private

- (NSMutableDictionary*) locationsNames {
	@synchronized(self) {
		if (!_locationsNames)
			_locationsNames = [self.cacheRecord.data.data mutableCopy];
		return _locationsNames;
	}
}

- (NSDictionary*) conquerableStations {
	@synchronized(self) {
		if (!_conquerableStations || [self.conquerableStationsRecord.expireDate compare:[NSDate date]] == NSOrderedAscending) {
			EVEConquerableStationList* stationList = [EVEConquerableStationList conquerableStationListWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:nil progressHandler:nil];
			if (stationList) {
				NSMutableDictionary* conquerableStations = [NSMutableDictionary new];
				for (EVEConquerableStationListItem* item in stationList.outposts)
					conquerableStations[@(item.stationID)] = item;
				_conquerableStations = conquerableStations;
				[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
					self.conquerableStationsRecord.data.data = _conquerableStations;
					self.conquerableStationsRecord.date = [NSDate date];
					self.conquerableStationsRecord.expireDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 *7];
				}];
			}
		}
		else
			_conquerableStations = self.conquerableStationsRecord.data.data;
		return _conquerableStations;
	}
}

- (NCCacheRecord*) cacheRecord {
	@synchronized(self) {
		if (!_cacheRecord) {
			[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
				_cacheRecord = [NCCacheRecord cacheRecordWithRecordID:NSStringFromClass(self.class)];
				if ([_cacheRecord.expireDate compare:[NSDate date]] == NSOrderedAscending) {
					_cacheRecord.data.data = nil;
					_cacheRecord.expireDate = [NSDate distantPast];
				}
			}];
		}
		return _cacheRecord;
	}
}

- (NCCacheRecord*) conquerableStationsRecord {
	@synchronized(self) {
		if (!_conquerableStationsRecord) {
			[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
				_conquerableStationsRecord = [NCCacheRecord cacheRecordWithRecordID:@"EVEConquerableStationList"];
			}];
		}
		return _conquerableStationsRecord;
	}
}


- (void) didReceiveMemoryWarning {
	@synchronized(self) {
		self.locationsNames = nil;
		self.cacheRecord = nil;
	}
}

@end
