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

@interface NCTableViewController ()
@property (nonatomic, strong, readwrite) NCTaskManager* taskManager;
@property (nonatomic, strong, readwrite) NCCacheRecord* cacheRecord;
@property (nonatomic, strong, readwrite) id data;
@property (nonatomic, strong) NSMutableDictionary* sectionsCollapsState;
@property (nonatomic, strong) NSDictionary* previousCollapsState;
@property (nonatomic, strong) NSMutableDictionary* offscreenCells;
@property (nonatomic, strong) NSMutableDictionary* estimatedRowHeights;

- (IBAction) onRefresh:(id) sender;

- (void) progressStepWithTask:(NCTask*) task;
- (void) updateCacheTime;
- (void) didChangeAccountNotification:(NSNotification*) notification;
- (void) didBecomeActive:(NSNotification*) notification;
- (void) onLongPress:(UILongPressGestureRecognizer*) recognizer;
- (void) collapsAll:(UIMenuController*) controller;
- (void) expandAll:(UIMenuController*) controller;

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
//	self.tableView.estimatedRowHeight = self.tableView.rowHeight;
//	self.tableView.rowHeight = UITableViewAutomaticDimension;
	
	self.estimatedRowHeights = [NSMutableDictionary new];
	
	self.preferredContentSize = CGSizeMake(320, 768);
	self.offscreenCells = [NSMutableDictionary new];
	
	if (!self.tableView.backgroundView) {
		UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
		view.backgroundColor = [UIColor clearColor];
		self.tableView.backgroundView = view;
	}
	
	self.tableView.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
	self.tableView.separatorColor = [UIColor appearanceTableViewSeparatorColor];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccountNotification:) name:NCAccountDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStorage) name:NCStorageDidChangeNotification object:nil];

	UIRefreshControl* refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
	refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@" "
																		  attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14],
																					   NSForegroundColorAttributeName: [UIColor whiteColor]}];
	self.refreshControl = refreshControl;

	
	if ([self.tableView isKindOfClass:[CollapsableTableView class]]) {
		[self.tableView registerClass:[NCTableViewCollapsedHeaderView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewHeaderView"];
	}
	else {
		[self.tableView registerClass:[NCTableViewHeaderView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewHeaderView"];
	}
	
	if (self.searchDisplayController)
		[self.searchDisplayController.searchResultsTableView registerClass:[NCTableViewHeaderView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewHeaderView"];
	
	if ([self.tableView isKindOfClass:[CollapsableTableView class]]) {
		NSString* key = NSStringFromClass(self.class);
		NCStorage* storage = [NCStorage sharedStorage];
		NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
		[context performBlockAndWait:^{
			NCSetting* setting = [[NCStorage sharedStorage] settingWithKey:key];
			self.previousCollapsState = setting.value;
		}];
	}
	self.sectionsCollapsState = [NSMutableDictionary new];
	
	[self performSelector:@selector(update) withObject:nil afterDelay:0];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCAccountDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCStorageDidChangeNotification object:nil];
	[_taskManager cancelAllOperations];
//	self.searchDisplayController.searchResultsDataSource = nil;
//	self.searchDisplayController.searchResultsDelegate = nil;
//	self.searchDisplayController.delegate = nil;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	if ([self isViewLoaded] && self.view.window == nil) {
		self.cacheRecord = nil;
		self.data = nil;
		if (self.searchDisplayController && self.searchDisplayController.active)
			[self.searchDisplayController setActive:NO animated:NO];
	}
}



- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.taskManager.active = YES;
	if (!self.cacheRecord)
		[self reloadFromCache];
	else if ([self shouldReloadData])
		[self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.taskManager.active = NO;
	
	if ([self.tableView isKindOfClass:[CollapsableTableView class]]) {
		NSString* key = NSStringFromClass(self.class);
		NCStorage* storage = [NCStorage sharedStorage];
		NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
		[context performBlockAndWait:^{
			NCSetting* setting = [[NCStorage sharedStorage] settingWithKey:key];
			if (![self.sectionsCollapsState isEqualToDictionary:setting.value]) {
				if (![setting.value isEqualToDictionary:self.sectionsCollapsState]) {
					setting.value = self.sectionsCollapsState;
					[[NCStorage sharedStorage] saveContext];
				}
			}
		}];
	}

}

- (void) willMoveToParentViewController:(UIViewController *)parent {
	[super willMoveToParentViewController:parent];
	if (!parent) {
		[self.taskManager cancelAllOperations];
	}
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

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    //[self.refreshControl beginRefreshing];
}

- (BOOL) shouldReloadData {
	return [self isViewLoaded] && ([[self.cacheRecord expireDate] compare:[NSDate date]] == NSOrderedAscending ||
								   (![self.cacheRecord.data isFault] && !self.cacheRecord.data.data));
}

- (void) reloadFromCache {
	if (self.recordID) {

		NCCache* cache = [NCCache sharedCache];
		NSManagedObjectContext* context = cache.managedObjectContext;
		[context performBlockAndWait:^{
			self.cacheRecord = [NCCacheRecord cacheRecordWithRecordID:self.recordID];
		}];
		
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 [context performBlockAndWait:^{
													 [self performSelectorOnMainThread:@selector(progressStepWithTask:) withObject:task waitUntilDone:NO];
													 [self.cacheRecord.managedObjectContext performBlockAndWait:^{
														 [self.cacheRecord.data data];
													 }];
												 }];
											 }
								 completionHandler:^(NCTask *task) {
									 [NSObject cancelPreviousPerformRequestsWithTarget:self];
									 if (![task isCancelled]) {
										 if (!self.cacheRecord.data.data) {
											 [self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
										 }
										 else {
											 self.data = self.cacheRecord.data.data;
											 [self update];
											 
											 if ([self shouldReloadData])
												 [self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
										 }
									 }
								 }];
	}
}

- (NCCacheRecord*) didFinishLoadData:(id) data withCacheDate:(NSDate*) cacheDate expireDate:(NSDate*) expireDate {
	self.data = data;
	if (data) {
		NSString* recordID = self.recordID;
		NCCache* cache = [NCCache sharedCache];
		[cache.managedObjectContext performBlockAndWait:^{
			if (!self.cacheRecord || ![self.cacheRecord.recordID isEqualToString:recordID])
				self.cacheRecord = [NCCacheRecord cacheRecordWithRecordID:recordID];
			self.cacheRecord.recordID = recordID;
			self.cacheRecord.data.data = data;
			self.cacheRecord.date = cacheDate;
			self.cacheRecord.expireDate = expireDate;
			[cache saveContext];
		}];
	}
	[self update];
	return self.cacheRecord;
}

- (void) didUpdateData:(id) data {
	if (data) {
		self.data = data;
		NCCache* cache = [NCCache sharedCache];
		[cache.managedObjectContext performBlockAndWait:^{
			self.cacheRecord.data.data = data;
			[cache saveContext];
		}];

	}
}

- (void) didChangeStorage {
	[self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
}

- (void) didFailLoadDataWithError:(NSError*) error {
    [self.refreshControl endRefreshing];
}

- (void) update {
	[self.tableView reloadData];
	[self.refreshControl endRefreshing];
	[self updateCacheTime];

	//NSInteger sections = [self.tableView numberOfSections];
	//BOOL empty = sections == 0;
/*	for (NSInteger i = 0; i < sections; i++) {
		if ([self.tableView numberOfRowsInSection:i] > 0) {
			empty = NO;
			break;
		}
	}*/
/*	if (empty) {
		UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
		label.backgroundColor = [UIColor clearColor];
		label.textColor = [UIColor lightTextColor];
		label.font = [UIFont boldSystemFontOfSize:22];
		label.text = NSLocalizedString(@"No Results", nil);
		label.textAlignment = NSTextAlignmentCenter;
		self.tableView.backgroundView = label;
	}
	else
		self.tableView.backgroundView = nil;*/
}

- (NSTimeInterval) defaultCacheExpireTime {
	return 60 * 60;
}

- (NSString*) recordID {
	NCAccount* account = [NCAccount currentAccount];
	if (account) {
		return [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), account.uuid];
	}
	else
		return NSStringFromClass(self.class);
}

- (void) didChangeAccount:(NCAccount *)account {
	
}

- (void) searchWithSearchString:(NSString*) searchString {
	
}

- (NSDate*) cacheDate {
	return self.cacheRecord.date;
}

- (id) identifierForSection:(NSInteger)section {
	return nil;
}

- (BOOL) initiallySectionIsCollapsed:(NSInteger) section {
	return NO;
}

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

#pragma mark - UIScrollViewDelegate

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self updateCacheTime];
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
    [self reloadDataWithCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
}

- (void) progressStepWithTask:(NCTask*) task {
	task.progress += 0.1;
	if (task.progress < 0.9)
		[self performSelector:@selector(progressStepWithTask:) withObject:task afterDelay:0.1];
}

- (void) updateCacheTime {
	NSTimeInterval time = -[[self cacheDate] timeIntervalSinceNow];
	NSString* title;
	if (time < 60)
		title = NSLocalizedString(@"Updated a moment ago", nil);
	else
		title = [NSString stringWithFormat:NSLocalizedString(@"Updated %@ ago", nil),  [NSString stringWithTimeLeft:time componentsLimit:1]];
	
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:title
																		  attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14],
																					   NSForegroundColorAttributeName: [UIColor whiteColor]}];
}

- (void) didChangeAccountNotification:(NSNotification*) notification {
	[self didChangeAccount:notification.object];
}

- (void) didBecomeActive:(NSNotification *)notification {
	if ([self shouldReloadData])
		[self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
	else
		[self update];
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

@end
