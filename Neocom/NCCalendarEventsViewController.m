//
//  NCCalendarEventsViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 23.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCCalendarEventsViewController.h"
#import "EVEOnlineAPI.h"
#import "NSString+HTML.h"
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
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* rows = self.data;
	return rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSArray* rows = self.data;
	return rows.count > 0 ? [NSString stringWithFormat:NSLocalizedString(@"%d events", nil), (int32_t)rows.count] : NSLocalizedString(@"No events", nil);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray* rows = self.data;
	NCCalendarEventsViewControllerRow* row = rows[indexPath.row];
	
	
	static NSString *cellIdentifier = @"Cell";
	NCCalendarEventCell* cell = (NCCalendarEventCell*) [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (row.event.importance > 0)
		cell.titleLabel.text = [NSString stringWithFormat:@"\u2757%@", row.event.eventTitle];
	else
		cell.titleLabel.text = row.event.eventTitle;
	cell.event = row.event;
	
	static NSDateFormatter* dateFormatter = nil;
	if (!dateFormatter) {
		dateFormatter = [NSDateFormatter new];
		[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
		[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	}
	cell.dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ from %@", nil),
						   [dateFormatter stringFromDate:row.event.eventDate],
						   row.event.ownerID == 1 ? @"CCP" : row.event.ownerName];
	cell.eventTextLabel.text = row.shortDescription;
	
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 62;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account || account.accountType == NCAccountTypeCorporate) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	NSMutableArray* rows = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 EVEUpcomingCalendarEvents* calendarEvents = [EVEUpcomingCalendarEvents upcomingCalendarEventsWithKeyID:account.apiKey.keyID
																																			  vCode:account.apiKey.vCode
																																		cachePolicy:cachePolicy
																																		characterID:account.characterID
																																			  error:&error
																																	progressHandler:^(CGFloat progress, BOOL *stop) {
																																		task.progress = progress;
																																		if ([task isCancelled])
																																			*stop = YES;
																																	}];
											 for (EVEUpcomingCalendarEventsItem* event in calendarEvents.upcomingCalendarEvents) {
												 NCCalendarEventsViewControllerRow* row = [NCCalendarEventsViewControllerRow new];
												 row.event = event;
												 row.shortDescription = [[event.eventText stringByRemovingHTMLTags] stringByReplacingHTMLEscapes];
												 [rows addObject:row];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:rows withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
									 }
								 }
							 }];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}


@end
