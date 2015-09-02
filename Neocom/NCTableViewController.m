//
//  NCTableViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 12.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "NCCache.h"
#import "NCAccount.h"
#import "NSString+Neocom.h"
#import "NCTableViewHeaderView.h"
#import "NCTableViewCollapsedHeaderView.h"
#import "NCSetting.h"
#import "NCStorage.h"
#import "UIColor+Neocom.h"
#import "NCTableViewCell.h"
#import "NCAdaptivePopoverSegue.h"

@interface NCTableViewController ()<UISearchResultsUpdating>
@property (nonatomic, strong, readwrite) NCTaskManager* taskManager;
@property (nonatomic, strong, readwrite) id cacheData;
@property (nonatomic, strong) NCCacheRecord* cacheRecord;
@property (nonatomic, strong) NSMutableDictionary* sectionsCollapsState;
@property (nonatomic, strong) NSDictionary* previousCollapsState;
@property (nonatomic, strong) NSMutableDictionary* offscreenCells;
@property (nonatomic, strong) NSMutableDictionary* estimatedRowHeights;
@property (nonatomic, assign) BOOL loadingFromCache;
@property (nonatomic, assign) BOOL reloading;
@property (nonatomic, assign) BOOL initialSetupFinished;

- (IBAction) onRefresh:(id) sender;

- (void) progressStepWithTask:(NCTask*) task;
- (void) updateCacheTime;
- (void) onLongPress:(UILongPressGestureRecognizer*) recognizer;
- (void) collapsAll:(UIMenuController*) controller;
- (void) expandAll:(UIMenuController*) controller;
- (void) downloadDataWithCachePolicyInternal:(NSURLRequestCachePolicy) cachePolicy;
- (void) reloadIfNeeded;

@end

@implementation NCTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	//Appearance
	if (!self.tableView.backgroundView) {
		UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
		view.backgroundColor = [UIColor clearColor];
		self.tableView.backgroundView = view;
	}
	
	self.tableView.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
	self.tableView.separatorColor = [UIColor appearanceTableViewSeparatorColor];


	//Row heights support
	self.estimatedRowHeights = [NSMutableDictionary new];
	self.offscreenCells = [NSMutableDictionary new];

	//Popover support
	self.preferredContentSize = CGSizeMake(320, 768);


	//Application lifetime
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccount:) name:NCCurrentAccountDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStorage:) name:NCStorageDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];

	//Refresh support
	UIRefreshControl* refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
	refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@" "
																		  attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14],
																					   NSForegroundColorAttributeName: [UIColor whiteColor]}];
	self.refreshControl = refreshControl;

	
	//Table headers
	if ([self.tableView isKindOfClass:[CollapsableTableView class]])
		[self.tableView registerClass:[NCTableViewCollapsedHeaderView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewHeaderView"];
	else
		[self.tableView registerClass:[NCTableViewHeaderView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewHeaderView"];
	
	if (self.searchDisplayController)
		[self.searchDisplayController.searchResultsTableView registerClass:[NCTableViewHeaderView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewHeaderView"];
	
	//Collapse/expand support
	if ([self.tableView isKindOfClass:[CollapsableTableView class]]) {
		NSString* key = NSStringFromClass(self.class);

		[self.storageManagedObjectContext performBlock:^{
			NCSetting* setting = [self.storageManagedObjectContext settingWithKey:key];
			self.previousCollapsState = setting.value;
			dispatch_async(dispatch_get_main_queue(), ^{
				self.initialSetupFinished = YES;
				[self reloadIfNeeded];
			});
		}];
	}
	else
		self.initialSetupFinished = YES;
	self.sectionsCollapsState = [NSMutableDictionary new];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCCurrentAccountDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCStorageDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
	[_taskManager cancelAllOperations];
//	self.searchDisplayController.searchResultsDataSource = nil;
//	self.searchDisplayController.searchResultsDelegate = nil;
//	self.searchDisplayController.delegate = nil;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	if ([self isViewLoaded] && self.view.window == nil) {
		self.cacheRecord = nil;
		self.cacheData = nil;
		if (self.searchDisplayController && self.searchDisplayController.active)
			[self.searchDisplayController setActive:NO animated:NO];
	}
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.taskManager.active = YES;
	
	[self reloadIfNeeded];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.taskManager.active = NO;
	
	if ([self.tableView isKindOfClass:[CollapsableTableView class]]) {
		NSString* key = NSStringFromClass(self.class);
		id sectionsCollapsState = self.sectionsCollapsState;
		[self.storageManagedObjectContext performBlock:^{
			NCSetting* setting = [self.storageManagedObjectContext settingWithKey:key];
			if (![sectionsCollapsState isEqualToDictionary:setting.value]) {
				setting.value = sectionsCollapsState;
				[self.storageManagedObjectContext save:nil];
			}
		}];
	}
	[self.cacheManagedObjectContext performBlock:^{
		if ([self.cacheManagedObjectContext hasChanges])
			[self.cacheManagedObjectContext save:nil];
	}];
}

- (void) willMoveToParentViewController:(UIViewController *)parent {
	[super willMoveToParentViewController:parent];
	if (!parent) {
		[self.taskManager cancelAllOperations];
	}
}

- (void) setSearchController:(UISearchController *)searchController {
	_searchController = searchController;
	searchController.searchResultsUpdater = self;
	[searchController.searchBar sizeToFit];
	searchController.hidesNavigationBarDuringPresentation = NO;
	searchController.searchBar.barStyle = UIBarStyleBlack;
	searchController.searchBar.tintColor = [UIColor whiteColor];

	self.tableView.tableHeaderView = searchController.searchBar;
	self.definesPresentationContext = YES;

    NCTableViewController* searchResultsController = (NCTableViewController*) searchController.searchResultsController;
    searchResultsController.searchContentsController = self;
}

- (UINavigationController*) navigationController {
	UINavigationController* nc = [super navigationController];
	if (!nc) {
		if ([self.presentingViewController isKindOfClass:[self class]])
			nc = self.presentingViewController.navigationController;
	}
	return nc;
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isKindOfClass:[NCAdaptivePopoverSegue class]]) {
		NCAdaptivePopoverSegue* popoverSegue = (NCAdaptivePopoverSegue*) segue;
		popoverSegue.sender = sender;
	}
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	return action == @selector(collapsAll:) || action == @selector(expandAll:);
}

- (NCTaskManager*) taskManager {
	if (!_taskManager)
		_taskManager = [[NCTaskManager alloc] initWithViewController:self];
	return _taskManager;
}

- (NSManagedObjectContext*) storageManagedObjectContext {
	@synchronized (self) {
		if (!_storageManagedObjectContext)
			_storageManagedObjectContext = [[NCStorage sharedStorage] createManagedObjectContext];
		return _storageManagedObjectContext;
	}
}

- (NSManagedObjectContext*) databaseManagedObjectContext {
	@synchronized (self) {
		if (!_databaseManagedObjectContext)
			_databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		return _databaseManagedObjectContext;
	}
}

- (NSManagedObjectContext*) cacheManagedObjectContext {
	@synchronized (self) {
		if (!_cacheManagedObjectContext)
			_cacheManagedObjectContext = [[NCCache sharedCache] createManagedObjectContext];
		return _cacheManagedObjectContext;
	}
}

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(NSError* error)) completionBlock progressBlock:(void(^)(float progress)) progressBlock {
	completionBlock(nil);
}

- (void) loadCacheData:(id) cacheData withCompletionBlock:(void(^)()) completionBlock {
	completionBlock();
}

- (void) reload {
	if (!self.searchContentsController && !self.loadingFromCache) {
		if (self.cacheManagedObjectContext) {
			self.loadingFromCache = YES;
			[self.cacheManagedObjectContext performBlock:^{
				NCCacheRecord* cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:self.cacheRecordID];
				id data = cacheRecord.data.data;
				
				BOOL isExpired = [cacheRecord isExpired];
				dispatch_async(dispatch_get_main_queue(), ^{
					self.cacheRecord = cacheRecord;
					
					if (data) {
						self.cacheData = data;
						
						[self loadCacheData:data withCompletionBlock:^{
							[self.tableView reloadData];
							if (isExpired && [self isViewLoaded] && self.view.window)
								[self downloadDataWithCachePolicyInternal:NSURLRequestUseProtocolCachePolicy];
						}];
					}
					else if ([self isViewLoaded] && self.view.window)
						[self downloadDataWithCachePolicyInternal:NSURLRequestUseProtocolCachePolicy];
					self.loadingFromCache = NO;
				});
			}];
		}
	}
}

- (void) invalidateCache {
	self.cacheRecord.expireDate = [NSDate distantPast];
}

- (void) saveCacheData:(id) data cacheDate:(NSDate*) cacheDate expireDate:(NSDate*) expireDate {
	if (data) {
		self.cacheData = data;
		self.cacheRecord.data.data = data;
		if (cacheDate)
			self.cacheRecord.date = cacheDate;
		if (expireDate)
			self.cacheRecord.expireDate = expireDate;
	}
}


- (void) searchWithSearchString:(NSString*) searchString {
}

- (void) setCacheRecordID:(NSString *)cacheRecordID {
	if (![_cacheRecordID isEqual:cacheRecordID]) {
		_cacheRecordID = cacheRecordID;
		self.cacheRecord = nil;
		if (cacheRecordID && [self isViewLoaded] && self.view.window)
			[self reloadIfNeeded];
	}
}

#pragma mark - Notifications

- (void) didChangeStorage:(NSNotification*) notification {
}

- (void) didChangeAccount:(NSNotification*) notification {
	
}

- (void) didBecomeActive:(NSNotification *)notification {
	if ([self isViewLoaded] && self.view.window)
		[self reloadIfNeeded];
}

- (void) willResignActive:(NSNotification*) notification {
	[self.cacheManagedObjectContext performBlock:^{
		if ([self.cacheManagedObjectContext hasChanges])
			[self.cacheManagedObjectContext save:nil];
	}];
}

- (void) managedObjectContextDidSave:(NSNotification*) notification {
	NSManagedObjectContext* context = notification.object;
	if (context.persistentStoreCoordinator == _storageManagedObjectContext.persistentStoreCoordinator) {
		[self.storageManagedObjectContext performBlock:^{
			[self.storageManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
		}];
	}
}

#pragma mark - CollaplableTableView

- (id) identifierForSection:(NSInteger)section {
	return nil;
}

- (BOOL) initiallySectionIsCollapsed:(NSInteger) section {
	return NO;
}

#pragma mark - UITableViewCell configuration

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {

}

- (id) tableView:(UITableView *)tableView offscreenCellWithIdentifier:(NSString*) identifier {
	id cell = self.offscreenCells[identifier];
	if (!cell)
		self.offscreenCells[identifier] = cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

- (NSAttributedString *)tableView:(UITableView *)tableView attributedTitleForHeaderInSection:(NSInteger)section {
	return nil;
}

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	[self searchWithSearchString:searchString];
	return NO;
}

- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	[self searchWithSearchString:controller.searchBar.text];
	return NO;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
	tableView.backgroundView = nil;
	tableView.backgroundColor = self.tableView.backgroundColor;
	tableView.separatorColor = self.tableView.separatorColor;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	[self searchWithSearchString:self.searchController.searchBar.text];
}


#pragma mark - UIScrollViewDelegate

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self updateCacheTime];
	[self.view.window endEditing:YES];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString* identifier = [self tableView:tableView cellIdentifierForRowAtIndexPath:indexPath];
	if (!identifier)
		return [super tableView:tableView cellForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell && tableView != self.tableView)
		cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
//	cell.frame = CGRectMake(0, 0, tableView.frame.size.width, [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath]);
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

#pragma mark - UITableViewDelegate

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSAttributedString* attributedTitle = [self tableView:tableView attributedTitleForHeaderInSection:section];
	NSString* title = nil;
	
	if (!attributedTitle && [self respondsToSelector:@selector(tableView:titleForHeaderInSection:)])
		title = [self tableView:tableView titleForHeaderInSection:section];
	
	if (title || attributedTitle) {
		NCTableViewHeaderView* view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCTableViewHeaderView"];
		if ([view isKindOfClass:[NCTableViewCollapsedHeaderView class]]) {
			BOOL recognizerExists = NO;
			for (UIGestureRecognizer* recognizer in view.gestureRecognizers) {
				if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
					recognizerExists = YES;
					break;
				}
			}
			if (!recognizerExists)
				[view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)]];
		}
		
		if (attributedTitle)
			view.textLabel.attributedText = attributedTitle;
		else
			view.textLabel.text = title;
		
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	UIView* view = [self tableView:tableView viewForHeaderInSection:section];
	return view ? 44 : 0;
//	return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 0;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	self.estimatedRowHeights[indexPath] = @(cell.frame.size.height);
	cell.backgroundColor = [UIColor appearanceTableViewCellBackgroundColor];
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSNumber* height = self.estimatedRowHeights[indexPath];
	if (height)
		return [height floatValue];
	else
		return self.tableView.rowHeight;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString* identifier = [self tableView:tableView cellIdentifierForRowAtIndexPath:indexPath];
	if (!identifier)
		return [super tableView:tableView heightForRowAtIndexPath:indexPath];

	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
		return UITableViewAutomaticDimension;

	
	NCTableViewCell* cell = [self tableView:tableView offscreenCellWithIdentifier:identifier];
	if ([cell isKindOfClass:[NCTableViewCell class]]) {
		[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
		cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
		[cell.contentView setNeedsLayout];
		[cell.layoutContentView setNeedsLayout];
		[cell layoutIfNeeded];
		return cell.layoutContentView.frame.size.height;
	}
	else
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
}

#pragma mark - CollapsableTableViewDelegate

- (BOOL) tableView:(UITableView *)tableView sectionIsCollapsed:(NSInteger) section {
	id identifier = [self identifierForSection:section];
	if (identifier) {
		NSNumber* state = self.sectionsCollapsState[identifier];
		if (!state) {
			state = self.previousCollapsState[identifier];
			if (!state)
				state = @([self initiallySectionIsCollapsed:section]);
			self.sectionsCollapsState[identifier] = state;
		}
		return [state boolValue];
	}
	else
		return [self initiallySectionIsCollapsed:section];
}

- (BOOL) tableView:(UITableView *)tableView canCollapsSection:(NSInteger) section {
	return YES;
}

- (void) tableView:(UITableView *)tableView didCollapsSection:(NSInteger) section {
	id identifier = [self identifierForSection:section];
	if (identifier)
		self.sectionsCollapsState[identifier] = @(YES);
}

- (void) tableView:(UITableView *)tableView didExpandSection:(NSInteger) section {
	id identifier = [self identifierForSection:section];
	if (identifier)
		self.sectionsCollapsState[identifier] = @(NO);
}

#pragma mark - Private

- (IBAction) onRefresh:(id) sender {
    [self downloadDataWithCachePolicyInternal:NSURLRequestReloadIgnoringLocalCacheData];
}

- (void) progressStepWithTask:(NCTask*) task {
	task.progress += 0.1;
	if (task.progress < 0.9)
		[self performSelector:@selector(progressStepWithTask:) withObject:task afterDelay:0.1];
}

- (void) updateCacheTime {
	[self.cacheRecord.managedObjectContext performBlock:^{
		NSTimeInterval time = -[[self.cacheRecord date] timeIntervalSinceNow];
		dispatch_async(dispatch_get_main_queue(), ^{
			NSString* title;
			if (time < 60)
				title = NSLocalizedString(@"Updated a moment ago", nil);
			else
				title = [NSString stringWithFormat:NSLocalizedString(@"Updated %@ ago", nil),  [NSString stringWithTimeLeft:time componentsLimit:1]];
			
			self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:title
																				  attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14],
																							   NSForegroundColorAttributeName: [UIColor whiteColor]}];
		});
	}];
}

- (void) onLongPress:(UILongPressGestureRecognizer*) recognizer {
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		[self becomeFirstResponder];
		UIMenuController* controller = [UIMenuController sharedMenuController];
		controller.menuItems = @[[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Collapse All", nil) action:@selector(collapsAll:)],
								 [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Expand All", nil) action:@selector(expandAll:)]];
		[controller setTargetRect:recognizer.view.bounds inView:recognizer.view];
		[controller setMenuVisible:YES animated:YES];
	}
}

- (void) collapsAll:(UIMenuController*) controller {
	[(CollapsableTableView*) self.tableView collapsAll];
}

- (void) expandAll:(UIMenuController*) controller {
	[(CollapsableTableView*) self.tableView expandAll];
}

- (void) downloadDataWithCachePolicyInternal:(NSURLRequestCachePolicy) cachePolicy {
    if (self.searchContentsController)
		[self loadCacheData:self.cacheData withCompletionBlock:^{
			[self.tableView reloadData];
		}];
	else if (!self.reloading) {
		self.reloading = YES;
		[self.refreshControl beginRefreshing];
		[self downloadDataWithCachePolicy:cachePolicy completionBlock:^(NSError *error) {
			self.reloading = NO;
			[self loadCacheData:self.cacheData withCompletionBlock:^{
				[self.tableView reloadData];
				[self.refreshControl endRefreshing];
			}];
		} progressBlock:nil];
	}
}

- (void) reloadIfNeeded {
	if (!self.initialSetupFinished)
		return;
	
	if (!self.cacheRecord && self.cacheRecordID)
		[self reload];
	else if (self.cacheRecord) {
		NCCacheRecord* cacheRecord = self.cacheRecord;
		[cacheRecord.managedObjectContext performBlock:^{
			if (!cacheRecord.data.data || [cacheRecord isExpired]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self downloadDataWithCachePolicyInternal:NSURLRequestUseProtocolCachePolicy];
				});
			}
		}];
	}
}

@end
