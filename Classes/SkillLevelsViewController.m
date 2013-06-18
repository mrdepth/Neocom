//
//  SkillLevelsViewController.m
//  EVEUniverse
//
//  Created by mr_depth on 28.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SkillLevelsViewController.h"
#import "TagCellView.h"
#import "UITableViewCell+Nib.h"

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
	[self setSkillLevelsTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.skillLevelsTableView reloadData];
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
	NSString *cellIdentifier = @"TagCellView";
	
	TagCellView *cell = (TagCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [TagCellView cellWithNibName:@"TagCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), indexPath.row];;
	cell.checkmarkImageView.image = self.currentLevel == indexPath.row ? [UIImage imageNamed:@"checkmark.png"] : nil;
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self.delegate skillLevelsViewController:self didSelectLevel:indexPath.row];
}


@end
