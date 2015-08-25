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
@property (nonatomic, strong, readonly) NCCacheRecord* cacheRecord;
@property (nonatomic, strong, readonly) id data;
@property (nonatomic, strong) UISearchController* searchController;
@property (nonatomic, weak) NCTableViewController* searchContentsController;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;

- (void) didFinishLoadData:(id) data withCacheDate:(NSDate*) cacheDate expireDate:(NSDate*) expireDate;
- (void) didUpdateData:(id) data;
- (void) didFailLoadDataWithError:(NSError*) error;
- (void) didChangeStorage;

#pragma mark - Override
- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy;
- (BOOL) shouldReloadData;
- (void) reloadFromCache;
- (void) update;
- (NSTimeInterval) defaultCacheExpireTime;
- (NSString*) recordID;
- (void) didChangeAccount:(NCAccount*) account;
- (void) searchWithSearchString:(NSString*) searchString;
- (NSDate*) cacheDate;
- (id) identifierForSection:(NSInteger) section;
- (BOOL) initiallySectionIsCollapsed:(NSInteger) section;

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath;
- (id) tableView:(UITableView *)tableView offscreenCellWithIdentifier:(NSString*) identifier;
- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSAttributedString *)tableView:(UITableView *)tableView attributedTitleForHeaderInSection:(NSInteger)section;


@end
