//
//  RSSFeedViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RSSFeedViewController.h"
#import "RSS.h"
#import "RSSFeedCellView.h"
#import "UITableViewCell+Nib.h"
#import "UIAlertView+Error.h"
#import "NSMutableString+HTML.h"
#import "EVEUniverseAppDelegate.h"
#import "Globals.h"
#import "RSSViewController.h"
#import "NSMutableString+RSSParser10.h"
#import "NSString+HTML.h"
#import "appearance.h"

@interface RSSFeedViewController()
@property (nonatomic, strong) NSMutableArray *rows;
- (void) loadData;

@end

#define DESCRIPTION_LENGTH 200

@implementation RSSFeedViewController

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	[self loadData];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.feedTitleLabel = nil;
	self.rows = nil;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.rows.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[[self tableView:tableView cellForRowAtIndexPath:indexPath] contentView] frame].size.height;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"RSSFeedCellView";
    
    RSSFeedCellView *cell = (RSSFeedCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell = [RSSFeedCellView cellWithNibName:@"RSSFeedCellView" bundle:nil reuseIdentifier:cellIdentifier];
	NSDictionary *row = [self.rows objectAtIndex:indexPath.row];
	cell.titleLabel.text = NSLocalizedString([row valueForKey:@"title"], nil);
	cell.dateLabel.text = [row valueForKey:@"date"];
	cell.descriptionLabel.text = [row valueForKey:@"description"];
	[cell layoutSubviews];

	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	RSSViewController *controller = [[RSSViewController alloc] initWithNibName:@"RSSViewController" bundle:nil];
	controller.rss = [[self.rows objectAtIndex:indexPath.row] valueForKey:@"item"];
	
//	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self presentModalViewController:controller animated:YES];
//	else
//		[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Private

- (void) loadData {
	NSMutableArray *values = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"RSSFeedViewController+loadData" name:NSLocalizedString(@"Loading RSS Feed", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NSError *error = nil;
		RSS *rss = [RSS rssWithContentsOfURL:self.url error:&error progressHandler:nil];
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"MMMM dd, yyyy hh:mm a"];
			float n = rss.feed.items.count;
			float i = 0;
			for (RSSItem *item in rss.feed.items) {
				weakOperation.progress = i++ / n;
				NSMutableString *description = [NSMutableString stringWithString:item.description ? item.description : @""];
				[description removeHTMLTags];
				[description replaceHTMLEscapes];
				[description removeSpaces];
				
				NSDictionary *row = [NSDictionary dictionaryWithObjectsAndKeys:
									 [item.title stringByReplacingHTMLEscapes], @"title",
									 item, @"item",
									 description.length > DESCRIPTION_LENGTH ? [NSString stringWithFormat:@"%@...", [description substringToIndex:DESCRIPTION_LENGTH]] : description, @"description",
									 [dateFormatter stringFromDate:item.updated], @"date",
									 nil];
				[values addObject:row];
			}
			[self.feedTitleLabel performSelectorOnMainThread:@selector(setText:) withObject:rss.feed.title waitUntilDone:NO];
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		self.rows = values;
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];

}

@end