//
//  SkillPlannerImportViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SkillPlannerImportViewController.h"
#import "Globals.h"
#import "CharacterCellView.h"
#import "NibTableViewCell.h"
#import "SkillPlanViewController.h"

@implementation SkillPlannerImportViewController
@synthesize plansTableView;
@synthesize delegate;

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

- (void) dealloc {
	[plansTableView release];
	[rows release];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Import";
	[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)] autorelease]];

	NSArray* files = [[NSFileManager defaultManager] subpathsAtPath:[Globals documentsDirectory]];
	rows = [[NSMutableArray alloc] init];
	for (NSString* file in files)
		if ([[file pathExtension] compare:@"xml" options:NSCaseInsensitiveSearch] == NSOrderedSame)
			[rows addObject:file];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.plansTableView = nil;
	[rows release];
	rows = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) onClose:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return rows.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"CharacterCellView";
	
	CharacterCellView *cell = (CharacterCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [CharacterCellView cellWithNibName:@"CharacterCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	cell.characterNameLabel.text = [[rows objectAtIndex:indexPath.row] stringByDeletingPathExtension];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return @"Skill Plans";
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
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 37;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	SkillPlanViewController* controller = [[SkillPlanViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"SkillPlanViewController-iPad" : @"SkillPlanViewController")
																					bundle:nil];
	controller.skillPlanPath = [[Globals documentsDirectory] stringByAppendingPathComponent:[rows objectAtIndex:indexPath.row]];
	controller.skillPlannerImportViewController = self;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

@end
