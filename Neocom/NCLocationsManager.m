//
//  NCLocationsManager.m
//  Neocom
//
//  Created by Артем Шиманский on 17.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCLocationsManager.h"
#import "NCCache.h"
#import <EVEAPI/EVEAPI.h>
#import "NCDatabase.h"

@implementation NCLocationsManagerItem

- (id) initWithName:(NSString*) name solarSystemID:(int32_t) solarSystemID {
	if (self = [super init]) {
		self.name = name;
		self.solarSystemID = solarSystemID;
	}
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.name = [aDecoder decodeObjectForKey:@"name"];
		self.solarSystemID = [aDecoder decodeInt32ForKey:@"solarSystemID"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.name)
		[aCoder encodeObject:self.name forKey:@"name"];
	if (self.solarSystemID)
		[aCoder encodeInt32:self.solarSystemID forKey:@"solarSystemID"];
}

@end


@interface NCLocationsManager()
@property (nonatomic, strong) NSManagedObjectContext* databaseManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext* cacheManagedObjectContext;
- (void) didReceiveMemoryWarning;
- (void) requestConquerableStationsWithCompletionBlock:(void (^)(NSDictionary* conquerableStations))completionBlock;
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

- (void) requestLocationsNamesWithIDs:(NSArray*) ids completionBlock:(void(^)(NSDictionary* locationsNames)) completionBlock {
	[self requestConquerableStationsWithCompletionBlock:^(NSDictionary* conquerableStations) {
		[self.databaseManagedObjectContext performBlock:^{
			NSMutableArray* missingIDs = [ids mutableCopy];
			NSMutableDictionary* results = [NSMutableDictionary new];
			
			for (NSNumber* locationID in ids) {
				int32_t locationIDl = [locationID intValue];
				NCLocationsManagerItem* name;
				
				if (66000000 < locationIDl && locationIDl < 66014933) { //staStations
					int32_t locationID = locationIDl - 6000001;
					NCDBStaStation *station = [self.databaseManagedObjectContext staStationWithStationID:locationID];
					if (station)
						name = [[NCLocationsManagerItem alloc] initWithName:station.stationName solarSystemID:station.solarSystem.solarSystemID];
				}
				else if (66014934 < locationIDl && locationIDl < 67999999) { //staStations
					int32_t locationID = locationIDl - 6000000;
					EVEConquerableStationListItem *conquerableStation = conquerableStations[@(locationID)];
					if (conquerableStation) {
						name = [[NCLocationsManagerItem alloc] initWithName:conquerableStation.stationName solarSystemID:conquerableStation.solarSystemID];
					}
				}
				else if (60014861 < locationIDl && locationIDl < 60014928) { //ConqStations
					EVEConquerableStationListItem *conquerableStation = conquerableStations[@(locationIDl)];
					if (conquerableStation) {
						name = [[NCLocationsManagerItem alloc] initWithName:conquerableStation.stationName solarSystemID:conquerableStation.solarSystemID];
					}
				}
				else if (60000000 < locationIDl && locationIDl < 61000000) { //staStations
					NCDBStaStation *station = [self.databaseManagedObjectContext staStationWithStationID:locationIDl];
					name = [[NCLocationsManagerItem alloc] initWithName:station.stationName solarSystemID:station.solarSystem.solarSystemID];
				}
				else if (61000000 <= locationIDl) { //ConqStations
					EVEConquerableStationListItem *conquerableStation = conquerableStations[@(locationIDl)];
					if (conquerableStation) {
						name = [[NCLocationsManagerItem alloc] initWithName:conquerableStation.stationName solarSystemID:conquerableStation.solarSystemID];
					}
				}
				else { //mapDenormalize
					NCDBMapDenormalize *denormalize = [self.databaseManagedObjectContext mapDenormalizeWithItemID:locationIDl];
					if (denormalize) {
						name = [[NCLocationsManagerItem alloc] initWithName:denormalize.itemName solarSystemID:denormalize.solarSystem.solarSystemID];
					}
				}
				
				if (name) {
					results[locationID] = name;
					[missingIDs removeObject:locationID];
				}
			}
			
			if (missingIDs.count > 0) {
				[self.cacheManagedObjectContext performBlock:^{
					NCCacheRecord* cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:@"EVEConquerableStationList"];
					
					NSMutableDictionary* locationsNames = [cacheRecord.data.data mutableCopy] ?: [NSMutableDictionary new];
					
					for (NSNumber* locationID in missingIDs) {
						NCLocationsManagerItem* name = locationsNames[locationID];
						if (name) {
							results[locationID] = name;
							[missingIDs removeObject:locationID];
						}
					}
					
					if (missingIDs.count > 0) {
						EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:nil cachePolicy:NSURLRequestUseProtocolCachePolicy];
						[api characterNameWithIDs:missingIDs completionBlock:^(EVECharacterName *result, NSError *error) {
							for (EVECharacterIDItem* item in result.characters) {
								NCLocationsManagerItem* name = [[NCLocationsManagerItem alloc] initWithName:item.name solarSystemID:0];
								results[@(item.characterID)] = name;
								locationsNames[@(item.characterID)] = name;
							}
							[self.cacheManagedObjectContext performBlock:^{
								cacheRecord.data.data = locationsNames;
								if ([cacheRecord.expireDate isEqualToDate:[NSDate distantPast]]) {
									cacheRecord.date = [NSDate date];
									cacheRecord.expireDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 7];
								}
								[self.cacheManagedObjectContext save:nil];
							}];
							
							dispatch_async(dispatch_get_main_queue(), ^{
								completionBlock(results);
							});
						} progressBlock:nil];
					}
					else {
						dispatch_async(dispatch_get_main_queue(), ^{
							completionBlock(results);
						});
					}
					
					
				}];
			}
			else
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(results);
				});
		}];
	}];
}

#pragma mark - Private

- (void) didReceiveMemoryWarning {
}

- (NSManagedObjectContext*) databaseManagedObjectContext {
	if (!_databaseManagedObjectContext)
		_databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
	return _databaseManagedObjectContext;
}

- (NSManagedObjectContext*) cacheManagedObjectContext {
	if (!_cacheManagedObjectContext)
		_cacheManagedObjectContext = [[NCCache sharedCache] createManagedObjectContext];
	return _cacheManagedObjectContext;
}

- (void) requestConquerableStationsWithCompletionBlock:(void (^)(NSDictionary* conquerableStations))completionBlock {
	[self.cacheManagedObjectContext performBlock:^{
		NCCacheRecord* cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:@"EVEConquerableStationList"];
		NSDictionary* conquerableStations = cacheRecord.data.data;
		if (!conquerableStations || [cacheRecord.expireDate compare:[NSDate date]] == NSOrderedAscending) {
			EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:nil cachePolicy:NSURLRequestUseProtocolCachePolicy];
			[api conquerableStationListWithCompletionBlock:^(EVEConquerableStationList *result, NSError *error) {
				if (result) {
					NSMutableDictionary* conquerableStations = [NSMutableDictionary new];
					for (EVEConquerableStationListItem* item in result.outposts)
						conquerableStations[@(item.stationID)] = item;
					dispatch_async(dispatch_get_main_queue(), ^{
						completionBlock(conquerableStations);
					});
					[self.cacheManagedObjectContext performBlock:^{
						cacheRecord.data.data = conquerableStations;
						cacheRecord.date = [NSDate date];
						cacheRecord.expireDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 *7];
						[self.cacheManagedObjectContext save:nil];
					}];
				}
				else {
					dispatch_async(dispatch_get_main_queue(), ^{
						completionBlock(conquerableStations);
					});
				}
			} progressBlock:nil];
		}
		else
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(conquerableStations);
			});
	}];
}

@end
