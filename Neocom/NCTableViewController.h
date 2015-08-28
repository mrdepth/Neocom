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
#import "NSManagedObjectContext+NCStorage.h"

@interface NCTableViewController : UITableViewController<UISearchDisplayDelegate, CollapsableTableViewDelegate>
@property (nonatomic, strong, readonly) NCTaskManager* taskManager;
@property (nonatomic, strong, readonly) id data;
@property (nonatomic, strong) UISearchController* searchController;
@property (nonatomic, weak) NCTableViewController* searchContentsController;
@property (nonatomic, strong) NSManagedObjectContext* storageManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext* databaseManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext* cacheManagedObjectContext;

- (void) updateData:(id) data;
- (void) didChangeStorage;
- (void) reloadFromCache;

#pragma mark - Override
- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(id data, NSDate* cacheDate, NSDate* expireDate, NSError* error)) completionBlock progressBlock:(void(^)(float progress)) progressBlock;

- (void) update;
- (NSTimeInterval) defaultCacheExpireTime;
- (void) requestRecordIDWithCompletionBlock:(void(^)(NSString* recordID)) completionBlock;

- (void) didChangeAccount:(NCAccount*) account;
- (void) searchWithSearchString:(NSString*) searchString;
- (id) identifierForSection:(NSInteger) section;
- (BOOL) initiallySectionIsCollapsed:(NSInteger) section;

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath;
- (id) tableView:(UITableView *)tableView offscreenCellWithIdentifier:(NSString*) identifier;
- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSAttributedString *)tableView:(UITableView *)tableView attributedTitleForHeaderInSection:(NSInteger)section;


@end
