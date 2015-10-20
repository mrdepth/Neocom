//
//  NCRSSFeedViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 05.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCRSSFeedViewController.h"
#import "NCRSSFeedCell.h"
#import "NCRSSItemViewController.h"
#import "RSSItem+Neocom.h"

@interface NSMutableString(RSS)

- (void) removeSpaces;

@end

@implementation NSMutableString(RSS)

- (void) removeSpaces {
	[self replaceOccurrencesOfString:@"\n" withString:@" " options:0 range:NSMakeRange(0, self.length)];
	[self replaceOccurrencesOfString:@"\r" withString:@" " options:0 range:NSMakeRange(0, self.length)];
	[self replaceOccurrencesOfString:@"\t" withString:@" " options:0 range:NSMakeRange(0, self.length)];
	int left = 5;
	while ([self replaceOccurrencesOfString:@"  " withString:@" " options:0 range:NSMakeRange(0, self.length)] && left)
		left--;
	if (self.length > 0 && [self characterAtIndex:0] == ' ')
		[self replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
}

@end


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
	self.cacheRecordID = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), self.url];
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
	NCRSSFeedViewControllerData* data = self.cacheData;
	return data.feed.items.count;
}

#pragma mark - NCTableViewController

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:2];
	[RSS rssWithContentsOfURL:self.url cachePolicy:cachePolicy completionBlock:^(RSS *result, NSError *error) {
		progress.completedUnitCount++;
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			@autoreleasepool {
				NSDateFormatter* dateFormatter = [NSDateFormatter new];
				[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
				[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];

				NCRSSFeedViewControllerData* data = [NCRSSFeedViewControllerData new];
				for (RSSItem* item in result.feed.items) {
					NSMutableString *s = [NSMutableString stringWithString:item.description ? item.description : @""];
					[s removeHTMLTags];
					[s replaceHTMLEscapes];
					[s removeSpaces];
					item.shortDescription = [s substringWithRange:NSMakeRange(0, MIN(s.length, 200))];
					item.plainTitle = [item.title stringByReplacingHTMLEscapes];
					item.updatedDateString = [dateFormatter stringFromDate:item.updated];
				}
				data.feed = result.feed;
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
					completionBlock(error);
					progress.completedUnitCount++;
				});
			}
		});
	} progressBlock:nil];
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCRSSFeedViewControllerData* data = self.cacheData;
	RSSItem* item = data.feed.items[indexPath.row];
	NCRSSFeedCell* cell = (NCRSSFeedCell*) tableViewCell;
	cell.object = item;
	cell.titleLabel.text = item.plainTitle;
	cell.dateLabel.text = item.updatedDateString;
	cell.rssItemText.text = item.shortDescription;
}

@end
