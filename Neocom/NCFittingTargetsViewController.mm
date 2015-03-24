//
//  NCFittingTargetsViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 03.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingTargetsViewController.h"
#import "NCTableViewCell.h"
#import "NCShipFit.h"
#import "eufe.h"

@interface NCFittingTargetsViewController ()

@end

@implementation NCFittingTargetsViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.selectedTarget)
		return self.targets.count + 1;
	else
		return self.targets.count;
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.targets.count)
		self.selectedTarget = nil;
	else
		self.selectedTarget = self.targets[indexPath.row];
	[self performSegueWithIdentifier:@"Unwind" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
	
	if (indexPath.row == self.targets.count) {
		cell.titleLabel.text = NSLocalizedString(@"Clear target", nil);
		cell.subtitleLabel.text = nil;
		cell.iconView.image = nil;
		cell.accessoryView = nil;
	}
	else {
		NCShipFit* fit = self.targets[indexPath.row];
		cell.titleLabel.text = [NSString stringWithFormat:@"%@ - %s", fit.type.typeName, fit.pilot->getCharacterName()];
		cell.subtitleLabel.text = fit.loadoutName;
		cell.iconView.image = fit.type.icon ? fit.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
		
		if (fit == self.selectedTarget)
			cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
		else
			cell.accessoryView = nil;
	}
}

@end
