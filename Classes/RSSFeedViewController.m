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
#import "NibTableViewCell.h"
#import "UIAlertView+Error.h"
#import "NSMutableString+HTML.h"
#import "EVEUniverseAppDelegate.h"
#import "Globals.h"
#import "RSSViewController.h"
#import "NSMutableString+RSSParser10.h"
#import "NSString+HTML.h"

@interface RSSFeedViewController(Private)

//- (void) didReceiveRSS:(RSS*) rss object:(id) object error:(NSError*) error;
- (void) loadData;

@end

#define DESCRIPTION_LENGTH 200

@implementation RSSFeedViewController
@synthesize rssTableView;
@synthesize feedTitleLabel;
@synthesize url;

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
	[self loadData];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.rssTableView = nil;
	self.feedTitleLabel = nil;
	[rows release];
	rows = nil;
}


- (void)dealloc {
	[rssTableView release];
	[feedTitleLabel release];
	[url release];
	[rows release];
    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return rows.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[[self tableView:tableView cellForRowAtIndexPath:indexPath] contentView] frame].size.height;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"RSSFeedCellView";
    
    RSSFeedCellView *cell = (RSSFeedCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell = [RSSFeedCellView cellWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"RSSFeedCellView-iPad" : @"RSSFeedCellView")
										 bundle:nil
								reuseIdentifier:cellIdentifier];
	NSDictionary *row = [rows objectAtIndex:indexPath.row];
	cell.titleLabel.text = [row valueForKey:@"title"];
	cell.dateLabel.text = [row valueForKey:@"date"];
	cell.descriptionLabel.text = [row valueForKey:@"description"];
	[cell layoutSubviews];
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	RSSViewController *controller = [[RSSViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"RSSViewController-iPad" : @"RSSViewController")
																		bundle:nil];
	controller.rss = [[rows objectAtIndex:indexPath.row] valueForKey:@"item"];
	
//	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self presentModalViewController:controller animated:YES];
//	else
//		[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

@end

@implementation RSSFeedViewController(Private)

- (void) loadData {
	NSMutableArray *values = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"RSSFeedViewController+loadData" name:@"Loading RSS Feed"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSError *error = nil;
		RSS *rss = [RSS rssWithContentsOfURL:url error:&error];
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"MMMM dd, yyyy hh:mm a"];
			float n = rss.feed.items.count;
			float i = 0;
			for (RSSItem *item in rss.feed.items) {
				operation.progress = i++ / n;
				NSMutableString *description = [NSMutableString stringWithString:item.description ? item.description : @""];
				[description removeHTMLTags];
				[description replaceHTMLEscapes];
				[description removeSpaces];
				
				//NSString *description = [[[item.description stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByRemovingHTMLTags] stringByReplacingHTMLEscapes];
				NSDictionary *row = [NSDictionary dictionaryWithObjectsAndKeys:
									 [item.title stringByReplacingHTMLEscapes], @"title",
									 item, @"item",
									 description.length > DESCRIPTION_LENGTH ? [NSString stringWithFormat:@"%@...", [description substringToIndex:DESCRIPTION_LENGTH]] : description, @"description",
									 [dateFormatter stringFromDate:item.updated], @"date",
									 nil];
				[values addObject:row];
			}
			[dateFormatter release];
			[self.feedTitleLabel performSelectorOnMainThread:@selector(setText:) withObject:rss.feed.title waitUntilDone:NO];
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		[rows release];
		rows = [values retain];
		[rssTableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];

}

@end