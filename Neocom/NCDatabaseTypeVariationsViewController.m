//
//  NCDatabaseTypeVariationsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 16.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeVariationsViewController.h"
#import "NCDatabaseTypeContainerViewController.h"

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
												 __block NSInteger parentTypeID = self.type.typeID;
												 [database execSQLRequest:[NSString stringWithFormat:@"SELECT parentTypeID FROM invMetaTypes WHERE typeID=%d;", parentTypeID]
															  resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																  NSInteger typeID = sqlite3_column_int(stmt, 0);
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
									 [self.tableView reloadData];
								 }];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NCDatabaseTypeContainerViewController* destinationViewController = segue.destinationViewController;
	NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
	destinationViewController.type = self.sections[indexPath.section][@"rows"][indexPath.row];
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
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell)
		cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	cell.textLabel.text = [row typeName];
	cell.imageView.image = [UIImage imageNamed:[row typeSmallImageName]];
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
}


@end
