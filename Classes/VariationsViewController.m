//
//  VariationsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 11.02.13.
//
//

#import "VariationsViewController.h"
#import "EVEDBAPI.h"
#import "ItemCellView.h"
#import "UITableViewCell+Nib.h"
#import "ItemViewController.h"
#import "EUOperationQueue.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface VariationsViewController ()
@property (nonatomic, retain) NSArray* sections;
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
	self.title = self.type.typeName;
	NSMutableArray* values = [NSMutableArray array];
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"VariationsViewController+Load" name:NSLocalizedString(@"Loading...", nil)];
	[operation addExecutionBlock:^{
		@autoreleasepool {
			EVEDBDatabase* database = [EVEDBDatabase sharedDatabase];
			__block NSInteger parentTypeID = self.type.typeID;
			[database execWithSQLRequest:[NSString stringWithFormat:@"SELECT * FROM invMetaTypes WHERE typeID=%d;", parentTypeID] resultBlock:^(NSDictionary *record, BOOL *needsMore) {
				NSInteger typeID = [[record valueForKey:@"parentTypeID"] integerValue];
				if (typeID)
					parentTypeID = typeID;
				*needsMore = NO;
			}];
			
			NSMutableDictionary* sections = [NSMutableDictionary dictionary];
			[database execWithSQLRequest:[NSString stringWithFormat:@"SELECT a.*, c.metaGroupName, c.metaGroupID FROM invTypes AS a LEFT JOIN invMetaTypes AS b ON a.typeID=b.typeID LEFT JOIN invMetaGroups AS c ON b.metaGroupID=c.metaGroupID LEFT JOIN dgmTypeAttributes AS d ON d.typeID=a.typeID AND d.attributeID=633 WHERE (b.parentTypeID=%d OR b.typeID=%d) AND marketGroupID IS NOT NULL ORDER BY d.value, typeName;", parentTypeID, parentTypeID]
							 resultBlock:^(NSDictionary *record, BOOL *needsMore) {
								 EVEDBInvType* type = [EVEDBInvType invTypeWithDictionary:record];
								 NSString* key = [record valueForKey:@"metaGroupID"];
								 if (!key)
									 key = @"z";
								 NSMutableDictionary* section = [sections valueForKey:key];
								 if (!section) {
									 NSString* title = [record valueForKey:@"metaGroupName"];
									 if (!title)
										 title = @"";
									 
									 section = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												title, @"title",
												[NSMutableArray arrayWithObject:type], @"rows",
												key, @"order", nil];
									 [sections setObject:section forKey:key];
								 }
								 else
									 [[section valueForKey:@"rows"] addObject:type];
								 
								 if ([operation isCancelled])
									 *needsMore = NO;
							 }];
			
			[values addObjectsFromArray:[[sections allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]]];
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![operation isCancelled]) {
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

- (void)dealloc {
    [_tableView release];
	[_sections release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setTableView:nil];
	self.sections = nil;
    [super viewDidUnload];
}

- (void) didSelectType:(EVEDBInvType*) type {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = type;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
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
	
	static NSString *cellIdentifier = @"ItemCellView";
	
	ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}

	EVEDBInvType *type = [[[self.sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	cell.titleLabel.text = type.typeName;
	cell.iconImageView.image = [UIImage imageNamed:[type typeSmallImageName]];
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[self.sections objectAtIndex:section] valueForKey:@"title"];
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
	view.collapsed = NO;
	view.titleLabel.text = title;
	view.collapsImageView.hidden = YES;
	return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self didSelectType:[[[self.sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row]];
}

@end
