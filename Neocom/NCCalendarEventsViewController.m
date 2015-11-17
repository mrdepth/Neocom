//
//  NCCalendarEventsViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 23.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCCalendarEventsViewController.h"
#import <EVEAPI/EVEAPI.h>
#import "NCCalendarEventCell.h"
#import "NCCalendarEventDetailsViewController.h"

@interface NCCalendarEventsViewControllerRow: NSObject<NSCoding>
@property (strong, nonatomic) EVEUpcomingCalendarEventsItem* event;
@property (strong, nonatomic) NSString* shortDescription;
@end

@implementation NCCalendarEventsViewControllerRow

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.event)
		[aCoder encodeObject:self.event forKey:@"event"];
	if (self.shortDescription)
		[aCoder encodeObject:self.shortDescription forKey:@"shortDescription"];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.event = [aDecoder decodeObjectForKey:@"event"];
		self.shortDescription = [aDecoder decodeObjectForKey:@"shortDescription"];
	}
	return self;
}

@end

@interface NCCalendarEventsViewController ()
@property (nonatomic, strong) NCAccount* account;

@end

@implementation NCCalendarEventsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.account = [NCAccount currentAccount];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCCalendarEventDetailsViewController"]) {
		NCCalendarEventDetailsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.event = [sender event];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.cacheData ? 1 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* rows = self.cacheData;
	return rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSArray* rows = self.cacheData;
	return rows.count > 0 ? [NSString stringWithFormat:NSLocalizedString(@"%d events", nil), (int32_t)rows.count] : nil;
}


#pragma mark - NCTableViewController

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NSArray* rows = cacheData;
	self.backgrountText = rows.count > 0 ? nil : NSLocalizedString(@"No Results", nil);
	completionBlock();
}

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	
	[account.managedObjectContext performBlock:^{
		__block NSError* lastError = nil;
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		[api upcomingCalendarEventsWithCompletionBlock:^(EVEUpcomingCalendarEvents *result, NSError *error) {
			NSMutableArray* rows = [NSMutableArray new];
			for (EVEUpcomingCalendarEventsItem* event in result.upcomingEvents) {
				NCCalendarEventsViewControllerRow* row = [NCCalendarEventsViewControllerRow new];
				row.event = event;
				row.shortDescription = [[event.eventText stringByRemovingHTMLTags] stringByReplacingHTMLEscapes];
				[rows addObject:row];
			}
			dispatch_async(dispatch_get_main_queue(), ^{
				[self saveCacheData:rows cacheDate:[NSDate date] expireDate:[result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]];
				completionBlock(lastError);
			});

		} progressBlock:nil];
	}];
}

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];

	self.account = [NCAccount currentAccount];
}

- (NSString *)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NSArray* rows = self.cacheData;
	NCCalendarEventsViewControllerRow* row = rows[indexPath.row];
	
	NCCalendarEventCell* cell = (NCCalendarEventCell*) tableViewCell;
	if (row.event.importance > 0)
		cell.titleLabel.text = [NSString stringWithFormat:@"\u2757%@", row.event.eventTitle];
	else
		cell.titleLabel.text = row.event.eventTitle;
	cell.event = row.event;
	
	static NSDateFormatter* dateFormatter = nil;
	if (!dateFormatter) {
		dateFormatter = [NSDateFormatter new];
		[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
		[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	}
	cell.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ from %@", nil),
						   [dateFormatter stringFromDate:row.event.eventDate],
						   row.event.ownerID == 1 ? @"CCP" : row.event.ownerName];
	cell.eventTextLabel.text = row.shortDescription;
}

#pragma mark - Private

- (void) setAccount:(NCAccount *)account {
	_account = account;
	[account.managedObjectContext performBlock:^{
		NSString* uuid = account.uuid;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.cacheRecordID = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), uuid];
		});
	}];
}

@end
