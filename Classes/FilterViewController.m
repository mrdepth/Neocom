//
//  FilterViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FilterViewController.h"
#import "GroupedCell.h"
#import "UITableViewCell+Nib.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "appearance.h"

@interface FilterViewController()
@property (nonatomic, strong) NSMutableIndexSet* collapsedSections;

@end

@implementation FilterViewController


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

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];

	self.title = NSLocalizedString(@"Filter", nil);
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onCancel:)]];
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDone:)]];
	}
    // Do any additional setup after loading the view from its nib.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	self.values = nil;
	self.collapsedSections = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.values = [NSMutableArray array];
	for (EUFilterItem *item in self.filter.filters)
		[self.values addObject:[item.values sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]]];
	
	[self.tableView reloadData];
}

- (IBAction) onDone:(id)sender {
	[self.delegate filterViewController:self didApplyFilter:self.filter];
}

- (IBAction) onCancel:(id)sender {
	[self.delegate filterViewControllerDidCancel:self];
}

- (void) setFilter:(EUFilter *)value {
	EUFilter *oldValue = self.filter;
	_filter = value;
	if (value != oldValue && self.navigationController.visibleViewController != self)
		[self.navigationController popViewControllerAnimated:NO];
	self.collapsedSections = [NSMutableIndexSet indexSet];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return self.values.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self.values objectAtIndex:section] count] + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return NSLocalizedString([[self.filter.filters objectAtIndex:section] name], nil);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];//[ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	
	EUFilterItem *filterItem = self.filter.filters[indexPath.section];
	if (indexPath.row == 0) {
		cell.textLabel.text = filterItem.allValue;
		cell.accessoryView = [[filterItem selectedValues] count] == 0 ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
	}
	else {
		EUFilterItemValue *value = [[self.values objectAtIndex:indexPath.section] objectAtIndex:indexPath.row - 1];
		cell.textLabel.text = value.title;
		cell.accessoryView = value.enabled ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
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
	EUFilterItem *filterItem = [self.filter.filters objectAtIndex:indexPath.section];
	if (indexPath.row == 0) {
		NSInteger row = 1;
		for (EUFilterItemValue *value in [self.values objectAtIndex:indexPath.section]) {
			if (value.enabled) {
				value.enabled = NO;
				GroupedCell *cell = (GroupedCell*) [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:indexPath.section]];
				cell.accessoryView = nil;
			}
			row++;
		}
		GroupedCell *cell = (GroupedCell*) [tableView cellForRowAtIndexPath:indexPath];
		cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
	}
	else {
		EUFilterItemValue *value = [[self.values objectAtIndex:indexPath.section] objectAtIndex:indexPath.row - 1];
		GroupedCell *cell = (GroupedCell*) [tableView cellForRowAtIndexPath:indexPath];
		value.enabled = !value.enabled;
		cell.accessoryView = value.enabled ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
		
		cell = (GroupedCell*) [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
		cell.accessoryView = [[filterItem selectedValues] count] == 0 ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
	}
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.delegate filterViewController:self didApplyFilter:self.filter];
	return;
}


#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	popoverController.popoverContentSize = CGSizeMake(320, 1100);
}

@end
