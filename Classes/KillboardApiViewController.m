//
//  KillboardApiViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 02.11.12.
//
//

#import "KillboardApiViewController.h"
#import "EUFilter.h"
#import "EUOperationQueue.h"
#import "EVEOnlineAPI.h"
#import "EVEAccount.h"
#import "UIAlertView+Error.h"
#import "NSDate+DaysAgo.h"
#import "CollapsableTableHeaderView.h"
#import "KillboardCellView.h"
#import "UITableViewCell+Nib.h"
#import "UIView+Nib.h"
#import "KillMailViewController.h"
#import "Globals.h"
#import "appearance.h"
#import "UIViewController+Neocom.h"

@interface KillboardApiViewController ()
@property (nonatomic, strong) NSMutableDictionary *charFilter;
@property (nonatomic, strong) NSMutableDictionary *corpFilter;
@property (nonatomic, strong) NSMutableDictionary* charKillLog;
@property (nonatomic, strong) NSMutableDictionary* corpKillLog;
@property (nonatomic, strong) NSArray* killLog;
@property (nonatomic, strong) NSArray* filteredValues;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL charEnd;
@property (nonatomic, assign) BOOL corpEnd;

- (void) reload;
- (void) searchWithSearchString:(NSString*) aSearchString;
- (void) didSelectAccount:(NSNotification*) notification;
@end

@implementation KillboardApiViewController

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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		//self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.ownerSegmentControl] autorelease];
		self.navigationItem.titleView = self.ownerSegmentControl;
	}
	self.title = NSLocalizedString(@"Kill Reports", nil);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.killboardTypeSegmentControl];
	//[self loadKillLogBeforeKillID:0 corporate:self.ownerSegmentControl.selectedSegmentIndex == 1];
	[self reload];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:EVEAccountDidSelectNotification object:nil];
    // Do any additional setup after loading the view from its nib.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self setOwnerSegmentControl:nil];
	[self setKillboardTypeSegmentControl:nil];
	[self setCharFilter:nil];
	[self setCorpFilter:nil];
	[self setCharKillLog:nil];
	[self setCorpKillLog:nil];
	[self setKillLog:nil];
	[self setFilteredValues:nil];
	[self setFilterNavigationViewController:nil];
	[self setFilterViewController:nil];
	[super viewDidUnload];
}

- (IBAction) onChangeOwner:(id) sender {
	[self reload];
//	[self filter];
}

- (IBAction) onChangeKillboardType:(id) sender {
	[self reload];
//	[self filter];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return self.filteredValues.count;
	else
		return self.killLog.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	NSDictionary* dic;
	if (self.searchDisplayController.searchResultsTableView == tableView)
		dic = [self.filteredValues objectAtIndex:section];
	else
		dic = [self.killLog objectAtIndex:section];
	return [[dic valueForKey:@"rows"] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"KillboardCellView";
	
    KillboardCellView *cell = (KillboardCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [KillboardCellView cellWithNibName:@"KillboardCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary* record;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		record = [[[self.filteredValues objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	else
		record = [[[self.killLog objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	
	EVEKillLogKill* kill = [record valueForKey:@"kill"];
	EVEDBInvType* ship = [record valueForKey:@"ship"];
	EVEDBMapSolarSystem* solarSystem = [record valueForKey:@"solarSystem"];
	
	cell.shipImageView.image = [UIImage imageNamed:ship.typeSmallImageName];
	cell.shipLabel.text = ship.typeName;
	cell.characterNameLabel.text = kill.victim.characterName;
	if (kill.victim.allianceID > 0) {
		cell.corporationNameLabel.text = kill.victim.corporationName;
		cell.allianceNameLabel.text = kill.victim.allianceName;
	}
	else {
		cell.corporationNameLabel.text = @"";
		cell.allianceNameLabel.text = kill.victim.corporationName;
	}
	
	if (solarSystem)
		cell.systemNameLabel.text = [NSString stringWithFormat:@"%@ (%.1f)", solarSystem.solarSystemName, solarSystem.security];
	cell.piratesLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Inv.: %d", nil), kill.attackers.count];
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSDictionary* dic;
	if (tableView == self.searchDisplayController.searchResultsTableView)
		dic = [self.filteredValues objectAtIndex:section];
	else
		dic = [self.killLog objectAtIndex:section];
	return [dic valueForKey:@"title"];
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 54;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary* record;
	if (self.searchDisplayController.searchResultsTableView == tableView)
		record = [[[self.filteredValues objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	else
		record = [[[self.killLog objectAtIndex:indexPath.section] valueForKey:@"rows"] objectAtIndex:indexPath.row];
	EVEKillLogKill* kill = [record valueForKey:@"kill"];

	EUOperation *operation = [EUOperation operationWithIdentifier:@"KillboardApiViewController+LoadKillMail" name:NSLocalizedString(@"Loading...", nil)];
	__weak EUOperation* weakOperation = operation;
	__block KillMail* killMail = nil;
	[operation addExecutionBlock:^(void) {
		@autoreleasepool {
			killMail = [[KillMail alloc] initWithKillLogKill:kill];
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			KillMailViewController* controller = [[KillMailViewController alloc] initWithNibName:@"KillMailViewController" bundle:nil];
			controller.killMail = killMail;
			[self.navigationController pushViewController:controller animated:YES];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

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

#pragma mark - UIScrollViewDelegate

/*- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	BOOL corporate = (self.ownerSegmentControl.selectedSegmentIndex == 1);
	if (self.loading || (corporate && self.corpEnd) || (!corporate && self.charEnd))
		return;
	if (scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentSize.height > 0) {
		NSDictionary* killLog = corporate ? self.corpKillLog : self.charKillLog;
		EVEKillLogKill* lastKill = [[[[[killLog valueForKey:@"kills"] lastObject] valueForKey:@"rows"] lastObject] valueForKey:@"kill"];
		EVEKillLogKill* lastLoss = [[[[[killLog valueForKey:@"losses"] lastObject] valueForKey:@"rows"] lastObject] valueForKey:@"kill"];
		NSInteger lastKillID = MIN(lastKill.killID, lastLoss.killID);
		if (lastKillID > 0)
			[self loadKillLogBeforeKillID:lastKillID corporate:corporate];
	}
}*/


#pragma mark - UISearchBarDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	[self searchWithSearchString:searchString];
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	[self searchWithSearchString:controller.searchBar.text];
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
	tableView.backgroundView = nil;
	tableView.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)aSearchBar {
	BOOL corporate = (self.ownerSegmentControl.selectedSegmentIndex == 1);
	NSString* killboardType = self.killboardTypeSegmentControl.selectedSegmentIndex == 0 ? @"kills" : @"losses";
	
	NSDictionary *filters = corporate ? self.corpFilter : self.charFilter;
	EUFilter* filter = [filters valueForKey:killboardType];

	self.filterViewController.filter = filter;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self presentViewControllerInPopover:self.filterNavigationViewController
									fromRect:self.searchDisplayController.searchBar.frame
									  inView:[self.searchDisplayController.searchBar superview]
					permittedArrowDirections:UIPopoverArrowDirectionUp
									animated:YES];
	else
		[self presentViewController:self.filterNavigationViewController animated:YES completion:nil];
	
}

#pragma mark - FilterViewControllerDelegate

- (void) filterViewController:(FilterViewController*) controller didApplyFilter:(EUFilter*) filter {
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		[self dismissViewControllerAnimated:YES completion:nil];
	[self reload];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void) reload {
	BOOL corporate = (self.ownerSegmentControl.selectedSegmentIndex == 1);
	NSMutableDictionary *currentKillLog = corporate ? self.corpKillLog : self.charKillLog;
	
	self.killLog = nil;
	if (!currentKillLog) {
		NSMutableDictionary* filterTmp = [NSMutableDictionary dictionary];
		[filterTmp setValue:[EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"killboardApiFilter" ofType:@"plist"]]]
					 forKey:@"kills"];
		[filterTmp setValue:[EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"killboardApiFilter" ofType:@"plist"]]]
					 forKey:@"losses"];

		if (corporate) {
			self.corpKillLog = [NSMutableDictionary dictionary];
			currentKillLog = self.corpKillLog;
		}
		else {
			self.charKillLog = [NSMutableDictionary dictionary];
			currentKillLog = self.charKillLog;
		}
		
		EVEAccount *account = [EVEAccount currentAccount];
		NSMutableDictionary *currentKillLogTmp = [NSMutableDictionary dictionary];
		
		EUOperation* operation = [EUOperation operationWithIdentifier:@"KillboardApiViewController+reload" name:NSLocalizedString(@"Loading Kill Log", nil)];
		__weak EUOperation* weakOperation = operation;
		
		[operation addExecutionBlock:^{
			@autoreleasepool {
				NSError* error = nil;
				EVEKillLog* killLog = corporate ?
				[EVEKillLog killLogWithKeyID:account.corpAPIKey.keyID vCode:account.corpAPIKey.vCode characterID:account.character.characterID beforeKillID:0 corporate:corporate error:&error progressHandler:nil] :
				[EVEKillLog killLogWithKeyID:account.charAPIKey.keyID vCode:account.charAPIKey.vCode characterID:account.character.characterID beforeKillID:0 corporate:corporate error:&error progressHandler:nil];
				weakOperation.progress = 0.5;
				if (error) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[[UIAlertView alertViewWithError:error] show];
					});
				}
				else {
					NSInteger charID = account.character.characterID;
					float n = [killLog.kills count];
					float i = 0;

					NSMutableDictionary* kills = [NSMutableDictionary dictionary];
					NSMutableDictionary* losses = [NSMutableDictionary dictionary];
					
					for (EVEKillLogKill* kill in [killLog.kills sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"killTime" ascending:NO]]]) {
						if ([weakOperation isCancelled])
							return;
						
						weakOperation.progress = 0.5 + n / i++ / 2;
						NSMutableDictionary* record = [NSMutableDictionary dictionaryWithObject:kill forKey:@"kill"];
						EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:kill.victim.shipTypeID error:nil];
						if (type)
							[record setValue:type forKey:@"ship"];

						EVEDBMapSolarSystem* solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:kill.solarSystemID error:nil];
						if (solarSystem)
							[record setValue:solarSystem forKey:@"solarSystem"];
						NSInteger days = [kill.killTime daysAgo];
						NSString* key = [NSDate stringWithDaysAgo:days];
						
						NSMutableDictionary* category;
						if ((corporate && kill.victim.corporationID == account.characterSheet.corporationID) || (!corporate && kill.victim.characterID == charID)) {
							category = losses;
							[[filterTmp valueForKey:@"losses"] updateWithValue:record];
						}
						else {
							category = kills;
							[[filterTmp valueForKey:@"kills"] updateWithValue:record];
						}
						
						
						NSMutableDictionary* section = [category valueForKey:key];
						if (!section) {
							section = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], @"rows", @(days), @"daysAgo", key, @"title", nil];
							[category setValue:section forKey:key];
						}
						[[section valueForKey:@"rows"] addObject:record];
					}
					
					
					NSArray* sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"daysAgo" ascending:YES]];
					[currentKillLogTmp setValue:[[kills allValues] sortedArrayUsingDescriptors:sortDescriptors] forKey:@"kills"];
					[currentKillLogTmp setValue:[[losses allValues] sortedArrayUsingDescriptors:sortDescriptors] forKey:@"losses"];
				}
			}
		}];
		
		[operation setCompletionBlockInMainThread:^{
			if (![weakOperation isCancelled]) {
				if (corporate)
					self.corpFilter = filterTmp;
				else
					self.charFilter = filterTmp;
				[currentKillLog addEntriesFromDictionary:currentKillLogTmp];
				[self reload];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		NSString* killboardType = self.killboardTypeSegmentControl.selectedSegmentIndex == 0 ? @"kills" : @"losses";
		
		NSDictionary *filters = corporate ? self.corpFilter : self.charFilter;
		EUFilter* filter = [filters valueForKey:killboardType];
		NSMutableArray* sections = [NSMutableArray array];
		if (filter) {
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"KillboardApiViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				for (NSDictionary* record in [currentKillLog valueForKey:killboardType]) {
					NSArray* rows = [filter applyToValues:[record valueForKey:@"rows"]];
					if (rows.count > 0) {
						[sections addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:rows, @"rows", [record valueForKey:@"title"], @"title", [record valueForKey:@"daysAgo"], @"daysAgo", nil]];
					}
				}
			}];
			
			[operation setCompletionBlockInMainThread:^(void) {
				if (![weakOperation isCancelled]) {
					if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						self.killLog = sections;
						[self searchWithSearchString:self.searchDisplayController.searchBar.text];
						[self.tableView reloadData];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else
			self.killLog = [currentKillLog valueForKey:killboardType];
	}
	[self.tableView reloadData];
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (self.killLog.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"KillboardApiViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@autoreleasepool {
			NSArray* keyPaths = @[@"kill.victim.characterName", @"kill.victim.corporationName", @"kill.victim.allianceName", @"ship.typeName"];
			for (NSDictionary *section in self.killLog) {
				if ([weakOperation isCancelled])
					break;
				NSMutableDictionary* filteredSections = [NSMutableDictionary dictionary];
				for (NSDictionary* row in [section valueForKey:@"rows"]) {
					for (NSString* keyPath in keyPaths) {
						NSString* value = [row valueForKeyPath:keyPath];
						if (value && [value rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
							NSString* key = [section valueForKey:@"title"];
							NSMutableDictionary* sectionTmp = [filteredSections valueForKey:key];
							if (!sectionTmp) {
								sectionTmp = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], @"rows", [section valueForKey:@"title"], @"title", [section valueForKey:@"daysAgo"], @"daysAgo", nil];
								[filteredSections setValue:sectionTmp forKey:key];
								[filteredValuesTmp addObject:sectionTmp];
							}
							[[sectionTmp valueForKey:@"rows"] addObject:row];
							break;
						}
					}
				}
			}
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.filteredValues = filteredValuesTmp;
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	self.charFilter = nil;
	self.corpFilter = nil;
	self.charKillLog = nil;
	self.corpKillLog = nil;
	self.killLog = nil;
	self.filteredValues = nil;

	if (!account && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		[self reload];
	}
}

@end
