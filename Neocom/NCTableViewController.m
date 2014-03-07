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
#import "CollapsableTableView.h"
#import "NCSetting.h"
#import "NCStorage.h"

@interface NCTableViewController ()
@property (nonatomic, strong, readwrite) NCTaskManager* taskManager;
@property (nonatomic, strong, readwrite) NCCacheRecord* cacheRecord;
@property (nonatomic, strong, readwrite) id data;
@property (nonatomic, strong) NSMutableDictionary* sectionsCollapsState;
@property (nonatomic, strong) NSDictionary* previousCollapsState;

- (IBAction) onRefresh:(id) sender;

- (void) progressStepWithTask:(NCTask*) task;
- (void) updateCacheTime;
- (void) didChangeAccountNotification:(NSNotification*) notification;
- (void) didBecomeActive:(NSNotification*) notification;

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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccountNotification:) name:NCAccountDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];

	UIRefreshControl* refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
	refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@" "
																		  attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14],
																					   NSForegroundColorAttributeName: [UIColor whiteColor]}];
	self.refreshControl = refreshControl;

	[self performSelector:@selector(update) withObject:nil afterDelay:0];
	//[self.tableView registerNib:[UINib nibWithNibName:@"NCTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NCTableViewHeaderView"];
	if ([self.tableView isKindOfClass:[CollapsableTableView class]])
		[self.tableView registerClass:[NCTableViewCollapsedHeaderView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewHeaderView"];
	else
		[self.tableView registerClass:[NCTableViewHeaderView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewHeaderView"];
	
	if ([self.tableView isKindOfClass:[CollapsableTableView class]]) {
		NSString* key = NSStringFromClass(self.class);
		[[[NCStorage sharedStorage] managedObjectContext] performBlockAndWait:^{
			NCSetting* setting = [NCSetting settingWithKey:key];
			self.previousCollapsState = setting.value;
		}];
	}
	self.sectionsCollapsState = [NSMutableDictionary new];
	//[self update];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCAccountDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
	[self.taskManager cancelAllOperations];
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
		[[[NCStorage sharedStorage] managedObjectContext] performBlockAndWait:^{
			NCSetting* setting = [NCSetting settingWithKey:key];
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
	if (data) {
		self.data = data;
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

- (void) didFailLoadDataWithError:(NSError*) error {
    [self.refreshControl endRefreshing];
}

- (void) update {

	[self.tableView reloadData];
	[self.refreshControl endRefreshing];
	[self updateCacheTime];

}

- (NSTimeInterval) defaultCacheExpireTime {
	return 60 * 60;
}

- (NSString*) recordID {
	NCAccount* account = [NCAccount currentAccount];
	if (account && !account.error) {
		return [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), [[account objectID] URIRepresentation]];
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
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self updateCacheTime];
}

#pragma mark - UITableViewDelegate

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if ([self respondsToSelector:@selector(tableView:titleForHeaderInSection:)]) {
		NSString* title = [self tableView:tableView titleForHeaderInSection:section];
		if (title) {
			NCTableViewHeaderView* view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCTableViewHeaderView"];
			return view;
		}
		else
			return nil;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UITableViewAutomaticDimension;
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
		return NO;
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

@end
