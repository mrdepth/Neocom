//
//  NCTableViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 12.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "NCCache.h"

@interface NCTableViewController ()
@property (nonatomic, strong, readwrite) NCTaskManager* taskManager;
@property (nonatomic, strong, readwrite) NCCacheRecord* cacheRecord;

- (IBAction) onRefresh:(id) sender;

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
	self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
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
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.taskManager.active = NO;
}

- (NCTaskManager*) taskManager {
	if (!_taskManager)
		_taskManager = [[NCTaskManager alloc] initWithViewController:self];
	return _taskManager;
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    [self.refreshControl beginRefreshing];
}

- (void) reloadFromCache {
	NCCache* cache = [NCCache sharedCache];
	NSManagedObjectContext* context = cache.managedObjectContext;
	
	__block NCCacheRecord* record = nil;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 [context performBlockAndWait:^{
												 record = [NCCacheRecord cacheRecordWithRecordID:self.recordID];
												 [record data];
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.cacheRecord = record;
									 if (!record.data) {
										 [self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
									 }
									 else {
										 [self update];
										 
										 if ([[record expireDate] compare:[NSDate date]] == NSOrderedAscending)
                                             [self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
									 }
								 }
							 }];
}

- (NCCacheRecord*) didFinishLoadData:(id) data withCacheDate:(NSDate*) cacheDate expireDate:(NSDate*) expireDate {
	NCCache* cache = [NCCache sharedCache];
//	NSManagedObjectContext* context = cache.managedObjectContext;

	if (!self.cacheRecord)
		self.cacheRecord = [NCCacheRecord cacheRecordWithRecordID:self.recordID];
		//self.cacheRecord = [[NCCacheRecord alloc] initWithEntity:[NSEntityDescription entityForName:@"Record" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	self.cacheRecord.recordID = self.recordID;
	self.cacheRecord.data = data;
	self.cacheRecord.date = cacheDate;
	self.cacheRecord.expireDate = expireDate;
	[cache saveContext];
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
	return 60;
}

- (NSString*) recordID {
	return NSStringFromClass(self.class);
}

#pragma mark - Private

- (IBAction) onRefresh:(id) sender {
    [self reloadDataWithCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
}

@end
