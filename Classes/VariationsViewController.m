//
//  VariationsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 11.02.13.
//
//

#import "VariationsViewController.h"
#import "EVEDBAPI.h"
#import "GroupedCell.h"
#import "ItemViewController.h"
#import "EUOperationQueue.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "appearance.h"

@interface VariationsViewController ()
@property (nonatomic, strong) NSArray* sections;
@end

@implementation VariationsViewController

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
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];

	self.title = self.type.typeName;
	NSMutableArray* values = [NSMutableArray array];
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"VariationsViewController+Load" name:NSLocalizedString(@"Loading...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^{
		@autoreleasepool {
			EVEDBDatabase* database = [EVEDBDatabase sharedDatabase];
			__block NSInteger parentTypeID = self.type.typeID;
			[database execSQLRequest:[NSString stringWithFormat:@"SELECT parentTypeID FROM invMetaTypes WHERE typeID=%d;", parentTypeID]
						 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
							 NSInteger typeID = sqlite3_column_int(stmt, 0);
							 if (typeID)
								 parentTypeID = typeID;
							 *needsMore = NO;
			}];
			
			NSMutableDictionary* sections = [NSMutableDictionary dictionary];
			[database execSQLRequest:[NSString stringWithFormat:@"SELECT c.*, a.* FROM invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE (b.parentTypeID=%d OR b.typeID=%d) AND marketGroupID IS NOT NULL ORDER BY d.value, typeName;", parentTypeID, parentTypeID]
							 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
								 EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
								 EVEDBInvMetaGroup* metaGroup = [[EVEDBInvMetaGroup alloc] initWithStatement:stmt];
								 NSNumber* key = metaGroup.metaGroupID > 0 ? @(metaGroup.metaGroupID) : @(INT_MAX);
								 NSMutableDictionary* section = [sections objectForKey:key];
								 if (!section) {
									 NSString* title = metaGroup.metaGroupName ? metaGroup.metaGroupName : @"";
									 
									 section = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												title, @"title",
												[NSMutableArray arrayWithObject:type], @"rows",
												key, @"order", nil];
									 [sections setObject:section forKey:key];
								 }
								 else
									 [[section valueForKey:@"rows"] addObject:type];
								 
								 if ([weakOperation isCancelled])
									 *needsMore = NO;
							 }];
			
			[values addObjectsFromArray:[[sections allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]]];
		}
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			self.sections = values;
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
	self.sections = nil;
    [super viewDidUnload];
}

- (void) didSelectType:(EVEDBInvType*) type {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = type;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	return [[[self.sections objectAtIndex:section] valueForKey:@"rows"] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *cellIdentifier = @"Cell";
    
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];//[ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	EVEDBInvType *type = [[[self.sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	cell.textLabel.text = type.typeName;
	cell.imageView.image = [UIImage imageNamed:[type typeSmallImageName]];
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[self.sections objectAtIndex:section] valueForKey:@"title"];
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self didSelectType:[[[self.sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row]];
}

@end
