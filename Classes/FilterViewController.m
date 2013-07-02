//
//  FilterViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FilterViewController.h"
#import "TagCellView.h"
#import "UITableViewCell+Nib.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundPopover~ipad.png"]];
		self.tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	else
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];

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
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSString *cellIdentifier = @"TagCellView";
	
	TagCellView *cell = (TagCellView*) [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [TagCellView cellWithNibName:@"TagCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	EUFilterItem *filterItem = [self.filter.filters objectAtIndex:indexPath.section];
	if (indexPath.row == 0) {
		cell.titleLabel.text = filterItem.allValue;
		//cell.checkmarkImageView.image = [[filterItem selectedValues] count] == 0 ? [UIImage imageNamed:@"checkmark.png"] : nil;
		cell.checkmarkImageView.image = [[filterItem selectedValues] count] == 0 ? [UIImage imageNamed:@"checkmark.png"] : nil;
	}
	else {
		EUFilterItemValue *value = [[self.values objectAtIndex:indexPath.section] objectAtIndex:indexPath.row - 1];
		cell.titleLabel.text = value.title;
		//cell.checkmarkImageView.image = value.enabled ? [UIImage imageNamed:@"checkmark.png"] : nil;
		cell.checkmarkImageView.image = value.enabled ? [UIImage imageNamed:@"checkmark.png"] : nil;
	}
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.collapsed = NO;
		view.titleLabel.text = title;
		if (tableView == self.searchDisplayController.searchResultsTableView)
			view.collapsImageView.hidden = YES;
		else
			view.collapsed = [self tableView:tableView sectionIsCollapsed:section];
		return view;
	}
	else
		return nil;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	EUFilterItem *filterItem = [self.filter.filters objectAtIndex:indexPath.section];
	if (indexPath.row == 0) {
		NSInteger row = 1;
		for (EUFilterItemValue *value in [self.values objectAtIndex:indexPath.section]) {
			if (value.enabled) {
				value.enabled = NO;
				TagCellView *cell = (TagCellView*) [aTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:indexPath.section]];
				cell.checkmarkImageView.image = nil;
			}
			row++;
		}
		TagCellView *cell = (TagCellView*) [aTableView cellForRowAtIndexPath:indexPath];
		cell.checkmarkImageView.image = [UIImage imageNamed:@"checkmark.png"];
	}
	else {
		EUFilterItemValue *value = [[self.values objectAtIndex:indexPath.section] objectAtIndex:indexPath.row - 1];
		TagCellView *cell = (TagCellView*) [aTableView cellForRowAtIndexPath:indexPath];
		value.enabled = !value.enabled;
		cell.checkmarkImageView.image = value.enabled ? [UIImage imageNamed:@"checkmark.png"] : nil;
		
		cell = (TagCellView*) [aTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
		cell.checkmarkImageView.image = [[filterItem selectedValues] count] == 0 ? [UIImage imageNamed:@"checkmark.png"] : nil;
	}
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.delegate filterViewController:self didApplyFilter:self.filter];
	return;
}

#pragma mark - CollapsableTableViewDelegate

- (BOOL) tableView:(UITableView *)tableView sectionIsCollapsed:(NSInteger) section {
	return [self.collapsedSections containsIndex:section];
}

- (BOOL) tableView:(UITableView *)tableView canCollapsSection:(NSInteger) section {
	return YES;
}

- (void) tableView:(UITableView *)tableView didCollapsSection:(NSInteger) section {
	[self.collapsedSections addIndex:section];
}

- (void) tableView:(UITableView *)tableView didExpandSection:(NSInteger) section {
	[self.collapsedSections removeIndex:section];
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	popoverController.popoverContentSize = CGSizeMake(320, 1100);
}

@end
