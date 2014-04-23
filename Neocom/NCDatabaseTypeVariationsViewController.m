//
//  NCDatabaseTypeVariationsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 16.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeVariationsViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCTableViewCell.h"

@interface NCDatabaseTypeVariationsViewController ()
@property (nonatomic, strong) NSArray* sections;

@end

@implementation NCDatabaseTypeVariationsViewController

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
	
	if (!self.sections) {
//		NSMutableArray* sections = [NSMutableArray new];
		__block NSArray* sections = nil;
		
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierNone
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 EVEDBDatabase* database = [EVEDBDatabase sharedDatabase];
												 __block int32_t parentTypeID = self.type.typeID;
												 [database execSQLRequest:[NSString stringWithFormat:@"SELECT parentTypeID FROM invMetaTypes WHERE typeID=%d;", parentTypeID]
															  resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																  int32_t typeID = sqlite3_column_int(stmt, 0);
																  if (typeID)
																	  parentTypeID = typeID;
																  *needsMore = NO;
															  }];
												 
												 NSMutableDictionary* sectionsDic = [NSMutableDictionary dictionary];
												 [database execSQLRequest:[NSString stringWithFormat:@"SELECT c.*, a.* FROM invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE (b.parentTypeID=%d OR b.typeID=%d) AND marketGroupID IS NOT NULL ORDER BY d.value, typeName;", parentTypeID, parentTypeID]
															  resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																  EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
																  EVEDBInvMetaGroup* metaGroup = [[EVEDBInvMetaGroup alloc] initWithStatement:stmt];
																  NSNumber* key = metaGroup.metaGroupID > 0 ? @(metaGroup.metaGroupID) : @(INT_MAX);
																  NSMutableDictionary* section = sectionsDic[key];
																  if (!section) {
																	  NSString* title = metaGroup.metaGroupName ? metaGroup.metaGroupName : @"";
																	  
																	  section = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																				 title, @"title",
																				 [NSMutableArray arrayWithObject:type], @"rows",
																				 key, @"order", nil];
																	  sectionsDic[key] = section;
																  }
																  else
																	  [section[@"rows"] addObject:type];
																  
																  if ([task isCancelled])
																	  *needsMore = NO;
															  }];
												 sections = [[sectionsDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]];
											 }
								 completionHandler:^(NCTask *task) {
									 self.sections = sections;
									 [self update];
								 }];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.type = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sections[section][@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	EVEDBInvType* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	static NSString *CellIdentifier = @"Cell";
	NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell)
		cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	cell.titleLabel.text = [row typeName];
	cell.iconView.image = [UIImage imageNamed:[row typeSmallImageName]];
	cell.object = row;
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
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

@end
