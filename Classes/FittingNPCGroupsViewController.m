//
//  FittingNPCGroupsViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FittingNPCGroupsViewController.h"
#import "FittingNPCItemViewController.h"
#import "DamagePattern.h"

@implementation FittingNPCGroupsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark -
#pragma mark Table view data source

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	if (self.searchDisplayController.searchResultsTableView == tableView || (self.category != nil && self.group != nil))
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	EVEDBInvType* type;
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		type = [self.filteredValues objectAtIndex:indexPath.row];
	}
	else {
		type = [self.rows objectAtIndex:indexPath.row];
	}
	FittingNPCItemViewController *controller = [[FittingNPCItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	controller.damagePatternsViewController = self.damagePatternsViewController;
	controller.type = type;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !self.modalMode) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:navController animated:YES];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		[self.damagePatternsViewController.delegate damagePatternsViewController:self.damagePatternsViewController
													 didSelectDamagePattern:[DamagePattern damagePatternWithNPCType:[self.filteredValues objectAtIndex:indexPath.row]]];
	}
	else if (self.category == nil) {
		FittingNPCGroupsViewController *controller = [[[self class] alloc] initWithNibName:self.nibName bundle:nil];
		controller.category = [self.rows objectAtIndex:indexPath.row];
		controller.damagePatternsViewController = self.damagePatternsViewController;
		controller.modalMode = self.modalMode;
		[self.navigationController pushViewController:controller animated:YES];
	}
	else if (self.group == nil) {
		FittingNPCGroupsViewController *controller = [[[self class] alloc] initWithNibName:self.nibName bundle:nil];
		controller.category = self.category;
		controller.group = [self.rows objectAtIndex:indexPath.row];
		controller.damagePatternsViewController = self.damagePatternsViewController;
		controller.modalMode = self.modalMode;
		[self.navigationController pushViewController:controller animated:YES];
	}
	else {
		[self.damagePatternsViewController.delegate damagePatternsViewController:self.damagePatternsViewController
													 didSelectDamagePattern:[DamagePattern damagePatternWithNPCType:[self.rows objectAtIndex:indexPath.row]]];
	}
}

@end
