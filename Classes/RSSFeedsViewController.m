//
//  RSSFeedsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RSSFeedsViewController.h"
#import "RSSFeedViewController.h"
#import "GroupedCell.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "appearance.h"

@interface RSSFeedsViewController()
@property (nonatomic, strong) NSArray *sections;

@end

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
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.sections = [[NSArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"rssFeeds" ofType:@"plist"]]];
	self.title = NSLocalizedString(@"News", nil);
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
	self.sections = nil;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[[self.sections objectAtIndex:section] valueForKey:@"feeds"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return NSLocalizedString([[self.sections objectAtIndex:section] valueForKey:@"title"], nil);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.imageView.image = [UIImage imageNamed:@"rss.png"];
	}
	
	cell.textLabel.text = [[[[self.sections objectAtIndex:indexPath.section] valueForKey:@"feeds"] objectAtIndex:indexPath.row] valueForKey:@"title"];
	
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	RSSFeedViewController *controller = [[RSSFeedViewController alloc] initWithNibName:@"RSSFeedViewController" bundle:nil];
	NSDictionary *rss = [[[self.sections objectAtIndex:indexPath.section] valueForKey:@"feeds"] objectAtIndex:indexPath.row];
	controller.url = [NSURL URLWithString:[rss valueForKey:@"url"]];
	controller.title = NSLocalizedString([rss valueForKey:@"title"], nil);
	[self.navigationController pushViewController:controller animated:YES];
}

@end
