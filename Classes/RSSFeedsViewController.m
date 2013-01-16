//
//  RSSFeedsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RSSFeedsViewController.h"
#import "RSSFeedViewController.h"
#import "RSSCellView.h"
#import "UITableViewCell+Nib.h"


@implementation RSSFeedsViewController

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
	sections = [[NSArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"rssFeeds" ofType:@"plist"]]];
	self.title = NSLocalizedString(@"News", nil);
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
	[sections release];
	sections = nil;
}


- (void)dealloc {
	[sections release];
    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[[sections objectAtIndex:section] valueForKey:@"feeds"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return NSLocalizedString([[sections objectAtIndex:section] valueForKey:@"title"], nil);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"RSSCellView";
    
    RSSCellView *cell = (RSSCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
		cell = [RSSCellView cellWithNibName:@"RSSCellView" bundle:nil reuseIdentifier:cellIdentifier];
	cell.titleLabel.text = [[[[sections objectAtIndex:indexPath.section] valueForKey:@"feeds"] objectAtIndex:indexPath.row] valueForKey:@"title"];
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = [self tableView:tableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:14];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	RSSFeedViewController *controller = [[RSSFeedViewController alloc] initWithNibName:@"RSSFeedViewController" bundle:nil];
	NSDictionary *rss = [[[sections objectAtIndex:indexPath.section] valueForKey:@"feeds"] objectAtIndex:indexPath.row];
	controller.url = [NSURL URLWithString:[rss valueForKey:@"url"]];
	controller.title = NSLocalizedString([rss valueForKey:@"title"], nil);
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

@end
