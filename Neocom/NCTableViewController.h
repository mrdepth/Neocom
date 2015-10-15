//
//  NCTableViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 12.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCCache.h"
#import "NCAccount.h"
#import "NCTaskManager.h"
#import "CollapsableTableView.h"
#import "NCDefaultTableViewCell.h"

@interface NCTableViewController : UITableViewController<UISearchDisplayDelegate, CollapsableTableViewDelegate>
@property (nonatomic, strong, readonly) NCTaskManager* taskManager;
@property (nonatomic, strong, readonly) id cacheData;
@property (nonatomic, strong) UISearchController* searchController;
@property (nonatomic, weak) NCTableViewController* searchContentsController;
@property (nonatomic, strong, readonly) NSManagedObjectContext* storageManagedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectContext* databaseManagedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectContext* cacheManagedObjectContext;
@property (nonatomic, strong) NSString* cacheRecordID;
@property (nonatomic, strong) NSProgress* progress;

- (void) saveCacheData:(id) data cacheDate:(NSDate*) cacheDate expireDate:(NSDate*) expireDate;
- (void) reload;
- (void) invalidateCache;

#pragma mark - Override
- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(NSError* error)) completionBlock;
- (void) loadCacheData:(id) cacheData withCompletionBlock:(void(^)()) completionBlock;

//Notifications
- (void) didChangeAccount:(NSNotification*) notification;
- (void) didBecomeActive:(NSNotification*) notification;
- (void) willResignActive:(NSNotification*) notification;
- (void) didChangeStorage:(NSNotification*) notification;
- (void) managedObjectContextDidFinishUpdate:(NSNotification*) notification;

- (void) searchWithSearchString:(NSString*) searchString completionBlock:(void(^)()) completionBlock;
- (id) identifierForSection:(NSInteger) section;
- (BOOL) initiallySectionIsCollapsed:(NSInteger) section;

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath;
- (id) tableView:(UITableView *)tableView offscreenCellWithIdentifier:(NSString*) identifier;
- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSAttributedString *)tableView:(UITableView *)tableView attributedTitleForHeaderInSection:(NSInteger)section;


@end
