//
//  NCDatabaseGroupPickerViewContoller.m
//  Neocom
//
//  Created by Артем Шиманский on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseGroupPickerViewContoller.h"
#import "NCTableViewCell.h"

@interface NCDatabaseGroupPickerViewContoller ()
@property (nonatomic, strong) NSArray* rows;
@end

@implementation NCDatabaseGroupPickerViewContoller

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.refreshControl = nil;
	
	if (!self.rows) {
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvGroup"];
		request.predicate = [NSPredicate predicateWithFormat:@"category.categoryID == %d", self.categoryID];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]];
		NCDatabase* database = [NCDatabase sharedDatabase];
		self.rows = [database.managedObjectContext executeFetchRequest:request error:nil];
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
		self.selectedGroup = [sender object];
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
	NCDBInvGroup* row = self.rows[indexPath.row];
	NCTableViewCell* cell = (NCTableViewCell*) tableViewCell;
	cell.titleLabel.text = row.groupName;
	
	cell.iconView.image = row.icon ? row.icon.image.image : [[[NCDBEveIcon defaultGroupIcon] image] image];
	cell.object = row;
}

@end
