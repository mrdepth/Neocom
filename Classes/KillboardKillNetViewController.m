//
//  KillboardKillNetViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import "KillboardKillNetViewController.h"
#import "EVEKillNetLog.h"
#import "KillboardCellView.h"
#import "UITableViewCell+Nib.h"
#import "UIView+Nib.h"
#import "CollapsableTableHeaderView.h"
#import "EVEDBAPI.h"
#import "EUOperationQueue.h"
#import "KillMailViewController.h"
#import "NSDate+DaysAgo.h"
#import "UIAlertView+Error.h"

@interface KillboardKillNetViewController ()
@property (nonatomic, retain) NSMutableArray* sections;

- (void) reload;
@end

@implementation KillboardKillNetViewController

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
	self.title = NSLocalizedString(@"EVE-Kill", nil);
	[self reload];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_tableView release];
	[_killLog release];
	[_sections release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setTableView:nil];
	[self setSections:nil];
    [super viewDidUnload];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[[self.sections objectAtIndex:section] valueForKey:@"rows"] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"KillboardCellView";
	
    KillboardCellView *cell = (KillboardCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [KillboardCellView cellWithNibName:@"KillboardCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary* record = [[[self.sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];

	EVEKillNetLogEntry* kill = [record valueForKey:@"kill"];
	EVEDBInvType* ship = [record valueForKey:@"ship"];
	NSString* solarSystem = [record valueForKey:@"solarSystem"];
	float solarSystemSecurity = [[record valueForKey:@"solarSystemSecurity"] floatValue];
	
	cell.shipImageView.image = [UIImage imageNamed:ship.typeSmallImageName];
	cell.shipLabel.text = ship.typeName;
	cell.characterNameLabel.text = kill.victimName;
	if (kill.victimAllianceName) {
		cell.corporationNameLabel.text = kill.victimCorpName;
		cell.allianceNameLabel.text = kill.victimAllianceName;
	}
	else {
		cell.corporationNameLabel.text = @"";
		cell.allianceNameLabel.text = kill.victimCorpName;
	}
	
	if (solarSystem)
		cell.systemNameLabel.text = [NSString stringWithFormat:@"%@ (%.1f)", solarSystem, solarSystemSecurity];
	cell.piratesLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Inv.: %d", nil), kill.involvedPartyCount];
	
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[self.sections objectAtIndex:section] valueForKey:@"title"];
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 52;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary* record = [[[self.sections objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"KillboardKillNetViewController+KillLoading" name:NSLocalizedString(@"Loading...", nil)];
	__block KillMail* killMail = nil;
	__block NSError* error = nil;
	[operation addExecutionBlock:^(void) {
		@autoreleasepool {
			EVEKillNetLogEntry* kill = [record valueForKey:@"kill"];
			EVEKillNetLog* killDetails = [EVEKillNetLog logWithFilter:@{EVEKillNetLogFilterKLLid : @(kill.internalID)} mask:EVEKillNetLogMaskAll error:&error];
			[error retain];
			if (killDetails.killLog.count > 0)
				killMail = [[KillMail alloc] initWithKillNetLogEntry:[killDetails.killLog objectAtIndex:0]];
			else
				error = [[NSError alloc] initWithDomain:@"EVE-Kill" code:0 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Kill details not found", nil)}];
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			if (error)
				[[UIAlertView alertViewWithError:error] show];
			else {
				KillMailViewController* controller = [[KillMailViewController alloc] initWithNibName:@"KillMailViewController" bundle:nil];
				controller.killMail = killMail;
				[self.navigationController pushViewController:controller animated:YES];
				[controller release];
			}
		}
		[error release];
		[killMail release];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.collapsed = NO;
		view.titleLabel.text = title;
		if (tableView == self.searchDisplayController.searchResultsTableView)
			view.collapsImageView.hidden = YES;
		else
			view.collapsed = [self tableView:tableView sectionIsCollapsed:section];
		return view;
	}
	else
		return nil;
}

#pragma mark - CollapsableTableViewDelegate

- (BOOL) tableView:(UITableView *)tableView sectionIsCollapsed:(NSInteger) section {
	return [[[self.sections objectAtIndex:section] valueForKey:@"collapsed"] boolValue];
}

- (BOOL) tableView:(UITableView *)tableView canCollapsSection:(NSInteger) section {
	return YES;
}

- (void) tableView:(UITableView *)tableView didCollapsSection:(NSInteger) section {
	[[self.sections objectAtIndex:section] setValue:@(YES) forKey:@"collapsed"];
}

- (void) tableView:(UITableView *)tableView didExpandSection:(NSInteger) section {
	[[self.sections objectAtIndex:section] setValue:@(NO) forKey:@"collapsed"];
}

#pragma mark - Private

- (void) reload {
	NSMutableArray* sectionsTmp = [NSMutableArray array];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"KillboardKillNetViewController+Loading" name:NSLocalizedString(@"Loading...", nil)];
	[operation addExecutionBlock:^(void) {
		@autoreleasepool {
			
			NSMutableDictionary* dic = [NSMutableDictionary dictionary];
			
			float i = 0;
			float n = self.killLog.killLog.count;
			for (EVEKillNetLogEntry* kill in [self.killLog.killLog sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]]) {
				if ([operation isCancelled])
					return;
				
				operation.progress = 0.5 + n / i++ / 2;
				NSMutableDictionary* record = [NSMutableDictionary dictionaryWithObject:kill forKey:@"kill"];
				EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:kill.victimShipID error:nil];
				if (type)
					[record setValue:type forKey:@"ship"];
				
				if (kill.solarSystemName) {
					[record setValue:kill.solarSystemName forKey:@"solarSystem"];
					[record setValue:@(kill.solarSystemSecurity) forKey:@"solarSystemSecurity"];
				}
				
				NSInteger days = [kill.timestamp daysAgo];
				NSString* key = [NSDate stringWithDaysAgo:days];
				
				NSMutableDictionary* section = [dic valueForKey:key];
				if (!section) {
					section = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], @"rows", @(days), @"daysAgo", key, @"title", nil];
					[dic setValue:section forKey:key];
				}
				[[section valueForKey:@"rows"] addObject:record];
			}
			
			
			NSArray* sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"daysAgo" ascending:YES]];
			[sectionsTmp addObjectsFromArray:[[dic allValues] sortedArrayUsingDescriptors:sortDescriptors]];
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			self.sections = sectionsTmp;
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
