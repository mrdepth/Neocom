//
//  NCTableViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 12.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCCache.h"
#import "NCTaskManager.h"

@interface NCTableViewController : UITableViewController
@property (nonatomic, strong, readonly) NCTaskManager* taskManager;
@property (nonatomic, strong, readonly) NCCacheRecord* cacheRecord;

- (NCCacheRecord*) didFinishLoadData:(id) data withCacheDate:(NSDate*) cacheDate expireDate:(NSDate*) expireDate;
- (void) didFailLoadDataWithError:(NSError*) error;

#pragma mark - Override
- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy;
- (BOOL) shouldReloadData;
- (void) update;
- (NSTimeInterval) defaultCacheExpireTime;
- (NSString*) recordID;

@end
