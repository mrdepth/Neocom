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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	
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
		cell.iconView.image = [UIImage imageNamed:[fit.type typeSmallImageName]];
		
		if (fit == self.selectedTarget)
			cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
		else
			cell.accessoryView = nil;
	}
	
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

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

@end
