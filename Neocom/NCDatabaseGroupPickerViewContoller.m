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
		NSMutableArray* rows = [NSMutableArray new];
		
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierNone
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 [[EVEDBDatabase sharedDatabase] execSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invGroups WHERE categoryID=%d AND published=1 ORDER BY groupName;", self.categoryID]
																					resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																						[rows addObject:[[EVEDBInvGroup alloc] initWithStatement:stmt]];
																						if ([task isCancelled])
																							*needsMore = NO;
																					}];
											 }
								 completionHandler:^(NCTask *task) {
									 self.rows = rows;
									 [self.tableView reloadData];
								 }];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	EVEDBInvGroup* row = self.rows[indexPath.row];
	NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell)
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
	
	cell.textLabel.text = row.groupName;
	
	NSString* iconImageName = row.icon.iconImageName;
	if (iconImageName)
		cell.imageView.image = [UIImage imageNamed:iconImageName];
	else
		cell.imageView.image = [UIImage imageNamed:@"Icons/icon38_174.png"];
	cell.object = row;
	return cell;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
