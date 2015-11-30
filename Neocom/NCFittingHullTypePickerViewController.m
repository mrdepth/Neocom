//
//  NCFittingHullTypePickerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 30.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingHullTypePickerViewController.h"
#import "NCTableViewCell.h"

@interface NCFittingHullTypePickerViewController ()
@property (nonatomic, strong) NSArray* rows;
@end

@implementation NCFittingHullTypePickerViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.refreshControl = nil;
	
	if (!self.rows) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EufeHullType"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"hullTypeName" ascending:YES]];
		self.rows = [self.databaseManagedObjectContext executeFetchRequest:request error:nil];
	}
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Unwind"]) {
		self.selectedHullType = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.rows.count;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCDBEufeHullType * row = self.rows[indexPath.row];
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	cell.titleLabel.text = row.hullTypeName;
	
	cell.iconView.image = [self.databaseManagedObjectContext eveIconWithIconFile:@"09_05"].image.image ?: [self.databaseManagedObjectContext defaultTypeIcon].image.image;
	cell.object = row;
	cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Signature %.0f m", nil), row.signature];
	if ([row.objectID isEqual:self.selectedHullType.objectID])
		cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
	else
		cell.accessoryView = nil;
	
}

@end
