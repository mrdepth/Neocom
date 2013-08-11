//
//  SkillLevelsViewController.m
//  EVEUniverse
//
//  Created by mr_depth on 28.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SkillLevelsViewController.h"
#import "UITableViewCell+Nib.h"
#import "UIViewController+Neocom.h"
#import "appearance.h"
#import "GroupedCell.h"

@implementation SkillLevelsViewController

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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.completionHandler = nil;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 6;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"Cell";
	
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), indexPath.row];
	cell.accessoryView = self.currentLevel == indexPath.row ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
	
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

- (void)tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	self.completionHandler(indexPath.row);
	self.completionHandler = nil;
	[self dismiss];
}


@end
