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

@interface NCTableViewController ()
@property (nonatomic, strong, readwrite) NCTaskManager* taskManager;
@property (nonatomic, strong, readwrite) NCCacheRecord* cacheRecord;

- (IBAction) onRefresh:(id) sender;

- (void) progressStepWithTask:(NCTask*) task;

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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccount:) name:NCAccountDidChangeNotification object:nil];
	self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
	[self update];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCAccountDidChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
}

- (void) willMoveToParentViewController:(UIViewController *)parent {
	[super willMoveToParentViewController:parent];
	if (!parent)
		[self.taskManager cancelAllOperations];
}

- (NCTaskManager*) taskManager {
	if (!_taskManager)
		_taskManager = [[NCTaskManager alloc] initWithViewController:self];
	return _taskManager;
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    [self.refreshControl beginRefreshing];
}

- (BOOL) shouldReloadData {
	return [[self.cacheRecord expireDate] compare:[NSDate date]] == NSOrderedAscending;
}

- (void) reloadFromCache {
	if (self.recordID) {
		NCCache* cache = [NCCache sharedCache];
		NSManagedObjectContext* context = cache.managedObjectContext;
		
		__block NCCacheRecord* record = nil;
		
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 [context performBlockAndWait:^{
													 [self performSelectorOnMainThread:@selector(progressStepWithTask:) withObject:task waitUntilDone:NO];
													 record = [NCCacheRecord cacheRecordWithRecordID:self.recordID];
													 [record data];
												 }];
											 }
								 completionHandler:^(NCTask *task) {
									 [NSObject cancelPreviousPerformRequestsWithTarget:self];
									 if (![task isCancelled]) {
										 self.cacheRecord = record;
										 if (!record.data) {
											 [self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
										 }
										 else {
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
		NCCache* cache = [NCCache sharedCache];
		if (!self.cacheRecord)
			self.cacheRecord = [NCCacheRecord cacheRecordWithRecordID:self.recordID];
		self.cacheRecord.recordID = self.recordID;
		self.cacheRecord.data = data;
		self.cacheRecord.date = cacheDate;
		self.cacheRecord.expireDate = expireDate;
		[cache saveContext];
	}
	[self update];
	return self.cacheRecord;
}

- (void) didFailLoadDataWithError:(NSError*) error {
    [self.refreshControl endRefreshing];
}

- (void) update {
	[self.tableView reloadData];
    [self.refreshControl endRefreshing];
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


#pragma mark - Private

- (IBAction) onRefresh:(id) sender {
    [self reloadDataWithCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
}

- (void) progressStepWithTask:(NCTask*) task {
	task.progress += 0.1;
	if (task.progress < 0.9)
		[self performSelector:@selector(progressStepWithTask:) withObject:task afterDelay:0.1];
}

@end
