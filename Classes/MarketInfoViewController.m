//
//  MarketInfoViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MarketInfoViewController.h"
#import "Globals.h"
#import "EVEDBAPI.h"
#import "MarketInfoCellView.h"
#import "UITableViewCell+Nib.h"
#import "EVEUniverseAppDelegate.h"
#import "UIAlertView+Error.h"
#import "appearance.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface MarketInfoViewController()
@property (nonatomic, strong) NSMutableArray *filteredSellOrdersRegions;
@property (nonatomic, strong) NSMutableArray *filteredBuyOrdersRegions;
@property (nonatomic, strong) NSMutableArray *filteredSellSummary;
@property (nonatomic, strong) NSMutableArray *filteredBuySummary;

- (void) loadData;
- (void) searchWithSearchString:(NSString*) searchString;

@end


@implementation MarketInfoViewController
@synthesize searchDisplayController;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.title = self.type.typeName;
	
	self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self.parentViewController];
	self.searchDisplayController.delegate = self;
	self.searchDisplayController.searchResultsDataSource = self;
	self.searchDisplayController.searchResultsDelegate = self;
	
	
	self.filteredSellOrdersRegions = [[NSMutableArray alloc] init];
	self.filteredBuyOrdersRegions = [[NSMutableArray alloc] init];
	self.filteredSellSummary = [[NSMutableArray alloc] init];
	self.filteredBuySummary = [[NSMutableArray alloc] init];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if (![userDefaults boolForKey:SettingsTipsMarketInfo]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning!", nil) message:NSLocalizedString(@"Market section does not provide market statistics in the realtime. Statistics is collected by the users during several days and may be not accurate. This information is cached on your device for 1 hour.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
		[alertView show];
		[userDefaults setBool:YES forKey:SettingsTipsMarketInfo];
	}
	[self loadData];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.reportTypeSegment = nil;
	self.searchBar = nil;
	self.searchDisplayController = nil;
	self.sellOrdersRegions = nil;
	self.buyOrdersRegions = nil;
	self.sellSummary = nil;
	self.buySummary = nil;
}

- (IBAction) onChangeReportTypeSegment: (id) sender {
	self.searchBar.selectedScopeButtonIndex = self.reportTypeSegment.selectedSegmentIndex;
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 0)
			return 2;
		else if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 1)
			return self.filteredSellOrdersRegions.count;
		else
			return self.filteredBuyOrdersRegions.count;
	}
	else {
		if (self.reportTypeSegment.selectedSegmentIndex == 0)
			return 2;
		else if (self.reportTypeSegment.selectedSegmentIndex == 1)
			return self.sellOrdersRegions.count;
		else
			return self.buyOrdersRegions.count;
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int count;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 0) {
			if (section == 0)
				count = self.filteredSellSummary.count;
			else
				count = self.filteredBuySummary.count;
		}
		else if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 1)
			count = [[[self.filteredSellOrdersRegions objectAtIndex:section] valueForKey:@"orders"] count];
		else
			count = [[[self.filteredBuyOrdersRegions objectAtIndex:section] valueForKey:@"orders"] count];
	}
	else {
		if (self.reportTypeSegment.selectedSegmentIndex == 0) {
			if (section == 0)
				count = self.sellSummary.count;
			else
				count = self.buySummary.count;
		}
		else if (self.reportTypeSegment.selectedSegmentIndex == 1)
			count = [[[self.sellOrdersRegions objectAtIndex:section] valueForKey:@"orders"] count];
		else
			count = [[[self.buyOrdersRegions objectAtIndex:section] valueForKey:@"orders"] count];
	}
	return count > 30 ? 30 : count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 0) {
			if (section == 0)
				return NSLocalizedString(@"Sell Orders", nil);
			else
				return NSLocalizedString(@"Buy Orders", nil);
		}
		else {
			if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 1)
				return [[self.filteredSellOrdersRegions objectAtIndex:section] valueForKey:@"region"];
			else
				return [[self.filteredBuyOrdersRegions objectAtIndex:section] valueForKey:@"region"];
		}
	}
	else {
		if (self.reportTypeSegment.selectedSegmentIndex == 0) {
			if (section == 0)
				return NSLocalizedString(@"Sell Orders", nil);
			else
				return NSLocalizedString(@"Buy Orders", nil);
		}
		else {
			if (self.reportTypeSegment.selectedSegmentIndex == 1)
				return [[self.sellOrdersRegions objectAtIndex:section] valueForKey:@"region"];
			else
				return [[self.buyOrdersRegions objectAtIndex:section] valueForKey:@"region"];
		}
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"MarketInfoCellView";
    
    MarketInfoCellView *cell = (MarketInfoCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [MarketInfoCellView cellWithNibName:@"MarketInfoCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	
	EVECentralQuickLookOrder *order;
	
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 0) {
			if (indexPath.section == 0)
				order = [self.filteredSellSummary objectAtIndex:indexPath.row];
			else
				order = [self.filteredBuySummary objectAtIndex:indexPath.row];
		}
		else if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 1)
			order = (EVECentralQuickLookOrder*) [[[self.filteredSellOrdersRegions objectAtIndex:indexPath.section] valueForKey:@"orders"] objectAtIndex:indexPath.row];
		else
			order = (EVECentralQuickLookOrder*) [[[self.filteredBuyOrdersRegions objectAtIndex:indexPath.section] valueForKey:@"orders"] objectAtIndex:indexPath.row];
	}
	else {
		if (self.reportTypeSegment.selectedSegmentIndex == 0) {
			if (indexPath.section == 0)
				order = [self.sellSummary objectAtIndex:indexPath.row];
			else
				order = [self.buySummary objectAtIndex:indexPath.row];
		}
		else if (self.reportTypeSegment.selectedSegmentIndex == 1)
			order = (EVECentralQuickLookOrder*) [[[self.sellOrdersRegions objectAtIndex:indexPath.section] valueForKey:@"orders"] objectAtIndex:indexPath.row];
		else
			order = (EVECentralQuickLookOrder*) [[[self.buyOrdersRegions objectAtIndex:indexPath.section] valueForKey:@"orders"] objectAtIndex:indexPath.row];
	}
	
	cell.systemLabel.text = order.region.regionName;
	cell.stationLabel.text = order.stationName;
	cell.securityLabel.text = [NSString stringWithFormat:@"%.1f", order.security < 0 ? 0 : order.security];

	int reported = [[NSDate date] timeIntervalSinceDate:order.reportedTime] / (3600 * 24);
	if (reported < 0)
		reported = 0;
	cell.reportedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Reported: %dd ago", nil), reported];
	if (order.security >= 0.5)
		cell.securityLabel.textColor = [UIColor greenColor];
	else if (order.security > 0)
		cell.securityLabel.textColor = [UIColor orangeColor];
	else
		cell.securityLabel.textColor = [UIColor redColor];
	cell.priceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:order.price] numberStyle:NSNumberFormatterDecimalStyle]];
	cell.qtyLabel.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:order.volRemain] numberStyle:NSNumberFormatterDecimalStyle];
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 53;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
	view.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
	return view;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 22;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.searchDisplayController.searchResultsTableView == tableView) {
	}
	else if (indexPath.section == 0) {
	}
	else {
	}
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	[self searchWithSearchString:searchString];
    return YES;
}


- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	[self searchWithSearchString:controller.searchBar.text];
    return YES;
}

- (void) searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
	self.reportTypeSegment.selectedSegmentIndex = selectedScope;
	[[NSUserDefaults standardUserDefaults] setInteger:selectedScope forKey:SettingsPublishedFilterKey];
	[self.tableView reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
	tableView.backgroundView = nil;
	tableView.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
}

#pragma mark - Private

- (void) loadData {
	NSMutableArray *sellOrdersRegionsTmp = [NSMutableArray array];
	NSMutableArray *buyOrdersRegionsTmp = [NSMutableArray array];
	NSMutableArray *sellSummaryTmp = [NSMutableArray array];
	NSMutableArray *buySummaryTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketInfoViewController+loadData" name:NSLocalizedString(@"Loading Market Info", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NSError *error = nil;
		EVECentralQuickLook *quickLook = [EVECentralQuickLook quickLookWithTypeID:self.type.typeID regionIDs:nil systemID:0 hours:0 minQ:0 error:&error progressHandler:nil];
		weakOperation.progress = 0.5;
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			NSMutableDictionary *sellOrdersRegionsDic = [NSMutableDictionary dictionary];
			NSMutableDictionary *buyOrdersRegionsDic = [NSMutableDictionary dictionary];
			
			[quickLook.sellOrders sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"price" ascending:YES]]];
			[quickLook.buyOrders sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"price" ascending:NO]]];
			
			for (EVECentralQuickLookOrder *order in quickLook.sellOrders) {
				NSDictionary *region = sellOrdersRegionsDic[@(order.regionID)];
				if (!region) {
					EVEDBMapRegion *mapRegion = [EVEDBMapRegion mapRegionWithRegionID:order.regionID error:nil];
					sellOrdersRegionsDic[@(order.regionID)] = @{@"orders": [NSMutableArray array], @"region": mapRegion.regionName};
				}
				NSMutableArray *orders = [region valueForKey:@"orders"];
				[orders addObject:order];
			}
			
			weakOperation.progress = 0.75;
			
			for (EVECentralQuickLookOrder *order in quickLook.buyOrders) {
				NSDictionary *region = buyOrdersRegionsDic[@(order.regionID)];
				if (!region) {
					EVEDBMapRegion *mapRegion = [EVEDBMapRegion mapRegionWithRegionID:order.regionID error:nil];
					buyOrdersRegionsDic[@(order.regionID)] = @{@"orders": [NSMutableArray array], @"region": mapRegion.regionName};
				}
				NSMutableArray *orders = [region valueForKey:@"orders"];
				[orders addObject:order];
			}
			
			[sellOrdersRegionsTmp addObjectsFromArray:[[sellOrdersRegionsDic allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"region" ascending:YES]]]];
			[buyOrdersRegionsTmp addObjectsFromArray:[[buyOrdersRegionsDic allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"region" ascending:YES]]]];
			
			
			[sellSummaryTmp addObjectsFromArray:quickLook.sellOrders];
			[buySummaryTmp addObjectsFromArray:quickLook.buyOrders];
		}
		weakOperation.progress = 1;
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		self.sellOrdersRegions = sellOrdersRegionsTmp;
		self.buyOrdersRegions = buyOrdersRegionsTmp;
		self.sellSummary = sellSummaryTmp;
		self.buySummary = buySummaryTmp;
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}


- (void) searchWithSearchString:(NSString*) aSearchString {
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredSellOrdersRegionsTmp = [NSMutableArray array];
	NSMutableArray *filteredBuyOrdersRegionsTmp = [NSMutableArray array];
	NSMutableArray *filteredSellSummaryTmp = [NSMutableArray array];
	NSMutableArray *filteredBuySummaryTmp = [NSMutableArray array];

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketInfoViewController+Filter" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		if ([weakOperation isCancelled])
			return;
		for (NSDictionary *item in self.sellOrdersRegions) {
			NSString *regionName = [item valueForKey:@"region"];
			NSMutableArray *orders = [NSMutableArray array];
			NSDictionary *region = [NSDictionary dictionaryWithObjectsAndKeys:orders, @"orders", regionName, @"region", nil];
			if ([regionName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
				[orders addObjectsFromArray:[item valueForKey:@"orders"]];
			}
			else {
				for (EVECentralQuickLookOrder *order in [item valueForKey:@"orders"]) {
					if ([order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
						[orders addObject:order];
					}
				}
			}
			if (orders.count > 0)
				[filteredSellOrdersRegionsTmp addObject:region];
		}
		weakOperation.progress = 0.25;
		
		for (NSDictionary *item in self.buyOrdersRegions) {
			NSString *regionName = [item valueForKey:@"region"];
			NSMutableArray *orders = [NSMutableArray array];
			NSDictionary *region = [NSDictionary dictionaryWithObjectsAndKeys:orders, @"orders", regionName, @"region", nil];
			if ([regionName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
				[orders addObjectsFromArray:[item valueForKey:@"orders"]];
			}
			else {
				for (EVECentralQuickLookOrder *order in [item valueForKey:@"orders"]) {
					if ([order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
						[orders addObject:order];
					}
				}
			}
			if (orders.count > 0)
				[filteredBuyOrdersRegionsTmp addObject:region];
		}
		weakOperation.progress = 0.5;
		for (EVECentralQuickLookOrder *order in self.sellSummary) {
			if ([order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
				(order.region && [order.region.regionName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
				[filteredSellSummaryTmp addObject:order];
			}
		}
		weakOperation.progress = 0.75;
		for (EVECentralQuickLookOrder *order in self.buySummary) {
			if ([order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
				(order.region && [order.region.regionName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
				[filteredBuySummaryTmp addObject:order];
			}
		}
		weakOperation.progress = 1;
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.filteredSellOrdersRegions = filteredSellOrdersRegionsTmp;
			self.filteredBuyOrdersRegions = filteredBuyOrdersRegionsTmp;
			self.filteredSellSummary = filteredSellSummaryTmp;
			self.filteredBuySummary = filteredBuySummaryTmp;
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end