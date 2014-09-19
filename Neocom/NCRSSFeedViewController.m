//
//  NCRSSFeedViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 05.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCRSSFeedViewController.h"
#import "RSS.h"
#import "NCRSSFeedCell.h"
#import "NSString+HTML.h"
#import "NSMutableString+HTML.h"
#import "NSMutableString+RSSParser10.h"
#import "NCRSSItemViewController.h"
#import "RSSItem+Neocom.h"

@interface NCRSSFeedViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) RSSFeed* feed;
@end

@implementation NCRSSFeedViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.feed = [aDecoder decodeObjectForKey:@"feed"];
		NSArray* shortDescriptions = [aDecoder decodeObjectForKey:@"shortDescriptions"];
		NSArray* plainTitles = [aDecoder decodeObjectForKey:@"plainTitles"];
		NSArray* dates = [aDecoder decodeObjectForKey:@"dates"];
		NSInteger i = 0;
		for (RSSItem* item in self.feed.items) {
			item.shortDescription = shortDescriptions[i];
			item.plainTitle = plainTitles[i];
			item.updatedDateString = dates[i];
			i++;
		}
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.feed)
		[aCoder encodeObject:self.feed forKey:@"feed"];
	NSMutableArray* shortDescriptions = [NSMutableArray new];
	NSMutableArray* plainTitles = [NSMutableArray new];
	NSMutableArray* dates = [NSMutableArray new];
	for (RSSItem* item in self.feed.items) {
		NSString* shortDescription = item.shortDescription;
		NSString* plainTitle = item.plainTitle;
		NSString* date = item.updatedDateString;
		[shortDescriptions addObject:shortDescription ? shortDescription : @""];
		[plainTitles addObject:plainTitle ? plainTitle : @""];
		[dates addObject:date ? date : @""];
	}
	[aCoder encodeObject:shortDescriptions forKey:@"shortDescriptions"];
	[aCoder encodeObject:plainTitles forKey:@"plainTitles"];
	[aCoder encodeObject:dates forKey:@"dates"];
}

@end

@interface NCRSSFeedViewController ()
@end

@implementation NCRSSFeedViewController

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
	if ([segue.identifier isEqualToString:@"NCRSSItemViewController"]) {
		NCRSSItemViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		controller.rss = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCRSSFeedViewControllerData* data = self.data;
	return data.feed.items.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCRSSFeedCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 57;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [self tableView:tableView offscreenCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell layoutIfNeeded];
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1)
		return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
	else
		return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize withHorizontalFittingPriority:1000 verticalFittingPriority:1].height + 1.0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), self.url];
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	__block NCRSSFeedViewControllerData* data = [NCRSSFeedViewControllerData new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NSDateFormatter* dateFormatter = [NSDateFormatter new];
											 [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
											 [dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];

											 RSS* rss = [RSS rssWithContentsOfURL:self.url error:&error progressHandler:^(CGFloat progress, BOOL *stop) {
												 task.progress = progress;
												 if ([task isCancelled])
													 *stop = YES;
											 }];
											 for (RSSItem* item in rss.feed.items) {
												 NSMutableString *s = [NSMutableString stringWithString:item.description ? item.description : @""];
												 [s removeHTMLTags];
												 [s replaceHTMLEscapes];
												 [s removeSpaces];
												 item.shortDescription = [s substringWithRange:NSMakeRange(0, MIN(s.length, 200))];
												 item.plainTitle = [item.title stringByReplacingHTMLEscapes];
												 item.updatedDateString = [dateFormatter stringFromDate:item.updated];
											 }
											 data.feed = rss.feed;
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:data withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
									 }
								 }
							 }];
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCRSSFeedViewControllerData* data = self.data;
	RSSItem* item = data.feed.items[indexPath.row];
	NCRSSFeedCell* cell = (NCRSSFeedCell*) tableViewCell;
	cell.object = item;
	cell.titleLabel.text = item.plainTitle;
	cell.dateLabel.text = item.updatedDateString;
	cell.rssItemText.text = item.shortDescription;
}

@end
