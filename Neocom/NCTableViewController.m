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
@property (nonatomic, strong, readwrite) NCCacheRecord* record;

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.taskManager.active = YES;
	if (!self.record)
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

- (void) reloadWithIgnoringCache:(BOOL) ignoreCache {

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
									 if (!record) {
										 [self reloadWithIgnoringCache:NO];
									 }
									 else {
										 self.record = record;
										 [self update];
										 
										 if ([[record expireDate] compare:[NSDate date]] == NSOrderedAscending)
											 [self reloadWithIgnoringCache:NO];
									 }
								 }
							 }];
}

- (void) didFinishLoadData:(id) data withCacheDate:(NSDate*) cacheDate expireDate:(NSDate*) expireDate {
	NCCache* cache = [NCCache sharedCache];
	NSManagedObjectContext* context = cache.managedObjectContext;

	if (!self.record)
		self.record = [[NCCacheRecord alloc] initWithEntity:[NSEntityDescription entityForName:@"Record" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	self.record.data = data;
	self.record.date = cacheDate;
	self.record.expireDate = expireDate;
	[cache saveContext];
	[self update];
}

- (void) update {
	[self.tableView reloadData];
}

- (NSTimeInterval) defaultCacheExpireTime {
	return 60;
}

- (NSString*) recordID {
	return NSStringFromClass(self.class);
}

@end
