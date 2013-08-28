//
//  AboutViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AboutViewController.h"
#import "Globals.h"
#import "EVEUniverseAppDelegate.h"
#import "EVEAccount.h"
#import "GroupedCell.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "NSNumberFormatter+Neocom.h"
#import "appearance.h"

@interface AboutViewController()
@property (nonatomic, assign) NSInteger cacheSize;
@property (nonatomic, strong) NSArray* specialThanks;

@end


@implementation AboutViewController

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
	NSURLCache* cache = [NSURLCache sharedURLCache];
	self.cacheSize = [cache currentDiskUsage] + [cache currentMemoryUsage];
	self.specialThanks = @[@"Peter Vlaar aka Tess La'Coil",
						@"Anton Vorobyov aka Kadesh Priestess",
						@"Kurt Otto",
						@"Toby Rayfield",
						@"Jim Nastik"];

	self.title = NSLocalizedString(@"About", nil);
//	self.databaseVersionLabel.text = @"Retribution_1.1_84566";
//	self.imagesVersionLabel.text = @"Retribution_1.1_imgs";
	
//	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
//	self.applicationVersionLabel.text = [NSString stringWithFormat:@"%@", [info valueForKey:@"CFBundleVersion"]];
	
//	[self reload];
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

- (IBAction) onClearCache:(id) sender {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning!", nil) message:NSLocalizedString(@"Some features may be temporarily unavailable.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Clear", nil), nil];
	[alertView show];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 5;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return 1;
	else if (section == 1)
		return 2;
	else if (section == 2)
		return 1;
	else if (section == 3)
		return self.specialThanks.count;
	else if (section == 4)
		return 4;
	else
		return 0;
		
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return NSLocalizedString(@"Cache", nil);
	else if (section == 1)
		return NSLocalizedString(@"Database", nil);
	else if (section == 2)
		return NSLocalizedString(@"Market", nil);
	else if (section == 3)
		return NSLocalizedString(@"Special thanks", nil);
	else if (section == 4)
		return NSLocalizedString(@"Application", nil);
	else
		return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCellStyle cellStyle;
	NSString* cellIdentifier = nil;
	if (indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 4) {
		cellStyle = UITableViewCellStyleValue1;
		cellIdentifier = @"ValueCell";
	}
	else {
		cellStyle = UITableViewCellStyleSubtitle;
		cellIdentifier = @"SubtitleCell";
	}
	
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
		cell = [[GroupedCell alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier];
	
	if (indexPath.section == 0) {
		cell.textLabel.text = NSLocalizedString(@"Cache size", nil);
		cell.detailTextLabel.text = [NSNumberFormatter neocomLocalizedStringFromInteger:self.cacheSize];
		cell.accessoryView = self.clearButton;
	}
	else {
		cell.accessoryView = nil;
		
		if (indexPath.section == 1) {
			if (indexPath.row == 0) {
				cell.textLabel.text = NSLocalizedString(@"Database", nil);
				cell.detailTextLabel.text = @"Retribution_1.1_84566";
			}
			else if (indexPath.row == 1) {
				cell.textLabel.text = NSLocalizedString(@"Images", nil);
				cell.detailTextLabel.text = @"Retribution_1.1_imgs";
			}
		}
		else if (indexPath.section == 2) {
			cell.textLabel.text = NSLocalizedString(@"Market information provided by", nil);
			cell.detailTextLabel.text = @"http://eve-central.com";
		}
		else if (indexPath.section == 3) {
			cell.textLabel.text = self.specialThanks[indexPath.row];
			cell.detailTextLabel.text = nil;
		}
		else if (indexPath.section == 4) {
			if (indexPath.row == 0) {
				cell.textLabel.text = NSLocalizedString(@"Version", nil);
				NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [info valueForKey:@"CFBundleVersion"]];
			}
			else if (indexPath.row == 1) {
				cell.textLabel.text = NSLocalizedString(@"Homepage", nil);
				cell.detailTextLabel.text = @"www.eveuniverseiphone.com";
			}
			else if (indexPath.row == 2) {
				cell.textLabel.text = NSLocalizedString(@"E-mail", nil);
				cell.detailTextLabel.text = @"support@eveuniverseiphone.com";
			}
			else if (indexPath.row == 3) {
				cell.textLabel.text = NSLocalizedString(@"Sources", nil);
				cell.detailTextLabel.text = @"https://github.com/mrdepth";
			}
		}
	}
	
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
	if (indexPath.section == 4) {
		if (indexPath.row == 1)
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.eveuniverseiphone.com"]];
		else if (indexPath.row == 2)
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:support@eveuniverseiphone.com"]];
		else if (indexPath.row == 3)
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/mrdepth"]];
	}
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[[NSURLCache sharedURLCache] removeAllCachedResponses];
		self.cacheSize = 0;
		[self.tableView reloadData];
	}
}

@end
