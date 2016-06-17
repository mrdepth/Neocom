//
//  NCPriceManager.m
//  Neocom
//
//  Created by Артем Шиманский on 03.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCPriceManager.h"
#import "NCCache.h"
#import <EVEAPI/EVEAPI.h>


@interface NCPriceManager()
@property (nonatomic, strong) NSManagedObjectContext* cacheManagedObjectContext;
@property (nonatomic, strong) AFHTTPRequestOperationManager* manager;
@property (atomic, assign) BOOL updating;
@property (assign, nonatomic) NSInteger triesLeft;
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
		AFHTTPRequestSerializer* requestSerializer = [AFHTTPRequestSerializer serializer];
		[requestSerializer setValue:@"application/vnd.ccp.eve.Api-v1+json" forHTTPHeaderField:@"Accept"];
		self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://crest-tq.eveonline.com"]];
		self.manager.requestSerializer = requestSerializer;
		self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
		self.manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"*/*", @"application/vnd.ccp.eve.markettypepricecollection-v1+json", nil];
		self.cacheManagedObjectContext = [[NCCache sharedCache] createManagedObjectContext];
		self.triesLeft = 5;
		[self updateIfNeeded];
	}
	return self;
}

- (void) requestPriceWithType:(NSInteger) typeID completionBlock:(void(^)(NSNumber* price)) completionBlock {
	[self requestPricesWithTypes:@[@(typeID)] completionBlock:^(NSDictionary *prices) {
		completionBlock(prices[@(typeID)]);
	}];
}

- (void) requestPricesWithTypes:(NSArray*) typeIDs completionBlock:(void(^)(NSDictionary* prices)) completionBlock {
	[self.cacheManagedObjectContext performBlock:^{
		NSMutableDictionary* prices = [NSMutableDictionary new];
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Price"];
		request.predicate = [NSPredicate predicateWithFormat:@"typeID in %@", [NSSet setWithArray:typeIDs]];
		for (NCCachePrice* price in [self.cacheManagedObjectContext executeFetchRequest:request error:nil])
			prices[@(price.typeID)] = @(price.price);
		dispatch_async(dispatch_get_main_queue(), ^{
			completionBlock(prices);
		});
	}];
}

- (void) updateIfNeeded {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	if (self.updating || self.triesLeft <= 0) {
		self.triesLeft = 0;
		return;
	}
	
	self.updating = YES;
	[self.cacheManagedObjectContext performBlock:^{
		NCCacheRecord* cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:@"NCPriceManager"];
		NSDate* date = cacheRecord.expireDate;
		if (!date || [date timeIntervalSinceNow] < 0) {
			[self.manager GET:@"https://crest-tq.eveonline.com/market/prices/" parameters:nil success:^void(AFHTTPRequestOperation * operation, id dic) {
				if ([dic isKindOfClass:[NSDictionary class]]) {
					[self.cacheManagedObjectContext performBlock:^{
						NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Price"];
						for (NCCachePrice* record in [self.cacheManagedObjectContext executeFetchRequest:request error:nil])
							[self.cacheManagedObjectContext deleteObject:record];
						
						for (NSDictionary* item in dic[@"items"]) {
							int32_t typeID = [item[@"type"][@"id"] intValue];
							NCCachePrice* record = [NSEntityDescription insertNewObjectForEntityForName:@"Price" inManagedObjectContext:self.cacheManagedObjectContext];
							record.typeID = typeID;
							double adjustedPrice = [item[@"adjustedPrice"] doubleValue];
							double averagePrice = [item[@"averagePrice"] doubleValue];
							record.price = averagePrice > 0 ? averagePrice : adjustedPrice;
						}
						cacheRecord.date = [NSDate date];
						cacheRecord.expireDate = [NSDate dateWithTimeIntervalSinceNow:3600 * 24];
						if ([self.cacheManagedObjectContext hasChanges])
							[self.cacheManagedObjectContext save:nil];
						self.updating = NO;
						self.triesLeft = 5;
						dispatch_async(dispatch_get_main_queue(), ^{
							[[NSNotificationCenter defaultCenter] postNotificationName:NCPriceManagerDidUpdateNotification object:nil];
						});
					}];
				}
				else {
					self.triesLeft--;
					self.updating = NO;
				}
			} failure:^void(AFHTTPRequestOperation * operation, NSError * error) {
				self.triesLeft--;
				self.updating = NO;
				[self performSelector:@selector(updateIfNeeded) withObject:0 afterDelay:10];
			}];
		}
		else
			self.updating = NO;
	}];
}

@end
