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
@property (nonatomic, strong, readonly) NCCacheRecord* record;

- (void) reload;
- (void) didFinishLoadData:(id) data withCacheDate:(NSDate*) cacheDate expireDate:(NSDate*) expireDate;
- (void) update;
- (NSTimeInterval) defaultCacheExpireTime;
- (NSString*) recordID;

@end
