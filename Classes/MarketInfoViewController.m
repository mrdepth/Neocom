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
#import "NibTableViewCell.h"
#import "EVEUniverseAppDelegate.h"
#import "UIAlertView+Error.h"

@interface MarketInfoViewController(Private)

- (void) loadData;
- (void) searchWithSearchString:(NSString*) searchString;

@end


@implementation MarketInfoViewController
@synthesize ordersTableView;
@synthesize reportTypeSegment;
@synthesize searchBar;
@synthesize searchDisplayController;
@synthesize parentViewController;
@synthesize type;
@synthesize sellOrdersRegions;
@synthesize buyOrdersRegions;
@synthesize sellSummary;
@synthesize buySummary;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = type.typeName;
	
	self.searchDisplayController = [[[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self.parentViewController] autorelease];
	self.searchDisplayController.delegate = self;
	self.searchDisplayController.searchResultsDataSource = self;
	self.searchDisplayController.searchResultsDelegate = self;
	
	
	filteredSellOrdersRegions = [[NSMutableArray alloc] init];
	filteredBuyOrdersRegions = [[NSMutableArray alloc] init];
	filteredSellSummary = [[NSMutableArray alloc] init];
	filteredBuySummary = [[NSMutableArray alloc] init];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if (![userDefaults boolForKey:SettingsTipsMarketInfo]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning!" message:@"Market section does not provide market statistics in the realtime. Statistics is collected by the users during several days and may be not accurate. This information is cached on your device for 1 hour." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		[userDefaults setBool:YES forKey:SettingsTipsMarketInfo];
	}
	[self loadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.ordersTableView = nil;
	self.reportTypeSegment = nil;
	self.searchBar = nil;
	self.searchDisplayController = nil;
	self.sellOrdersRegions = nil;
	self.buyOrdersRegions = nil;
	self.sellSummary = nil;
	self.buySummary = nil;
	
	[filteredSellOrdersRegions release];
	[filteredBuyOrdersRegions release];
	[filteredSellSummary release];
	[filteredBuySummary release];
	filteredSellOrdersRegions = nil;
	filteredBuyOrdersRegions = nil;
	filteredSellSummary = nil;
	filteredBuySummary = nil;
}



- (void)dealloc {
	[ordersTableView release];
	[reportTypeSegment release];
	[searchBar release];
	[searchDisplayController release];
	[type release];
	[sellOrdersRegions release];
	[buyOrdersRegions release];
	[sellSummary release];
	[buySummary release];
	
	[filteredSellOrdersRegions release];
	[filteredBuyOrdersRegions release];
	[filteredSellSummary release];
	[filteredBuySummary release];
	
    [super dealloc];
}

- (IBAction) onChangeReportTypeSegment: (id) sender {
	self.searchBar.selectedScopeButtonIndex = reportTypeSegment.selectedSegmentIndex;
	[ordersTableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 0)
			return 2;
		else if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 1)
			return filteredSellOrdersRegions.count;
		else
			return filteredBuyOrdersRegions.count;
	}
	else {
		if (reportTypeSegment.selectedSegmentIndex == 0)
			return 2;
		else if (reportTypeSegment.selectedSegmentIndex == 1)
			return sellOrdersRegions.count;
		else
			return buyOrdersRegions.count;
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int count;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 0) {
			if (section == 0)
				count = filteredSellSummary.count;
			else
				count = filteredBuySummary.count;
		}
		else if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 1)
			count = [[[filteredSellOrdersRegions objectAtIndex:section] valueForKey:@"orders"] count];
		else
			count = [[[filteredBuyOrdersRegions objectAtIndex:section] valueForKey:@"orders"] count];
	}
	else {
		if (reportTypeSegment.selectedSegmentIndex == 0) {
			if (section == 0)
				count = sellSummary.count;
			else
				count = buySummary.count;
		}
		else if (reportTypeSegment.selectedSegmentIndex == 1)
			count = [[[sellOrdersRegions objectAtIndex:section] valueForKey:@"orders"] count];
		else
			count = [[[buyOrdersRegions objectAtIndex:section] valueForKey:@"orders"] count];
	}
	return count > 30 ? 30 : count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 0) {
			if (section == 0)
				return @"Sell orders";
			else
				return @"Buy orders";
		}
		else {
			if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 1)
				return [[filteredSellOrdersRegions objectAtIndex:section] valueForKey:@"region"];
			else
				return [[filteredBuyOrdersRegions objectAtIndex:section] valueForKey:@"region"];
		}
	}
	else {
		if (reportTypeSegment.selectedSegmentIndex == 0) {
			if (section == 0)
				return @"Sell orders";
			else
				return @"Buy orders";
		}
		else {
			if (reportTypeSegment.selectedSegmentIndex == 1)
				return [[sellOrdersRegions objectAtIndex:section] valueForKey:@"region"];
			else
				return [[buyOrdersRegions objectAtIndex:section] valueForKey:@"region"];
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
				order = [filteredSellSummary objectAtIndex:indexPath.row];
			else
				order = [filteredBuySummary objectAtIndex:indexPath.row];
		}
		else if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 1)
			order = (EVECentralQuickLookOrder*) [[[filteredSellOrdersRegions objectAtIndex:indexPath.section] valueForKey:@"orders"] objectAtIndex:indexPath.row];
		else
			order = (EVECentralQuickLookOrder*) [[[filteredBuyOrdersRegions objectAtIndex:indexPath.section] valueForKey:@"orders"] objectAtIndex:indexPath.row];
	}
	else {
		if (reportTypeSegment.selectedSegmentIndex == 0) {
			if (indexPath.section == 0)
				order = [sellSummary objectAtIndex:indexPath.row];
			else
				order = [buySummary objectAtIndex:indexPath.row];
		}
		else if (reportTypeSegment.selectedSegmentIndex == 1)
			order = (EVECentralQuickLookOrder*) [[[sellOrdersRegions objectAtIndex:indexPath.section] valueForKey:@"orders"] objectAtIndex:indexPath.row];
		else
			order = (EVECentralQuickLookOrder*) [[[buyOrdersRegions objectAtIndex:indexPath.section] valueForKey:@"orders"] objectAtIndex:indexPath.row];
	}
	
	cell.systemLabel.text = order.region.regionName;
	cell.stationLabel.text = order.stationName;
	cell.securityLabel.text = [NSString stringWithFormat:@"%.1f", order.security < 0 ? 0 : order.security];

	int reported = [[NSDate date] timeIntervalSinceDate:order.reportedTime] / (3600 * 24);
	if (reported < 0)
		reported = 0;
	cell.reportedLabel.text = [NSString stringWithFormat:@"Reported: %dd ago", reported];
	if (order.security >= 0.5)
		cell.securityLabel.textColor = [UIColor greenColor];
	else if (order.security > 0)
		cell.securityLabel.textColor = [UIColor orangeColor];
	else
		cell.securityLabel.textColor = [UIColor redColor];
	cell.priceLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:order.price] numberStyle:NSNumberFormatterDecimalStyle]];
	cell.qtyLabel.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:order.volRemain] numberStyle:NSNumberFormatterDecimalStyle];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%f", order.price];
    // Configure the cell...
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 53;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = [self tableView:tableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:14];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
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
	reportTypeSegment.selectedSegmentIndex = selectedScope;
	[[NSUserDefaults standardUserDefaults] setInteger:selectedScope forKey:SettingsPublishedFilterKey];
	[ordersTableView reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
	tableView.backgroundColor = [UIColor clearColor];
	tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]] autorelease];	
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

@end

@implementation MarketInfoViewController(Private)

- (void) loadData {
	NSMutableArray *sellOrdersRegionsTmp = [NSMutableArray array];
	NSMutableArray *buyOrdersRegionsTmp = [NSMutableArray array];
	NSMutableArray *sellSummaryTmp = [NSMutableArray array];
	NSMutableArray *buySummaryTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketInfoViewController+loadData" name:@"Loading Market Info"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSError *error = nil;
		EVECentralQuickLook *quickLook = [EVECentralQuickLook quickLookWithTypeID:type.typeID regionIDs:nil systemID:0 hours:0 minQ:0 error:&error];
		operation.progress = 0.5;
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			NSMutableDictionary *sellOrdersRegionsDic = [NSMutableDictionary dictionary];
			NSMutableDictionary *buyOrdersRegionsDic = [NSMutableDictionary dictionary];
			
			[quickLook.sellOrders sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"price" ascending:YES]]];
			[quickLook.buyOrders sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"price" ascending:NO]]];
			
			for (EVECentralQuickLookOrder *order in quickLook.sellOrders) {
				NSString *regionID = [NSString stringWithFormat:@"%d", order.regionID];
				NSDictionary *region = [sellOrdersRegionsDic valueForKey:regionID];
				if (!region) {
					EVEDBMapRegion *mapRegion = [EVEDBMapRegion mapRegionWithRegionID:order.regionID error:nil];
					region = [NSDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], @"orders", mapRegion.regionName, @"region", nil];
					[sellOrdersRegionsDic setValue:region forKey:regionID];
				}
				NSMutableArray *orders = [region valueForKey:@"orders"];
				[orders addObject:order];
			}
			
			operation.progress = 0.75;
			
			for (EVECentralQuickLookOrder *order in quickLook.buyOrders) {
				NSString *regionID = [NSString stringWithFormat:@"%d", order.regionID];
				NSDictionary *region = [buyOrdersRegionsDic valueForKey:regionID];
				if (!region) {
					EVEDBMapRegion *mapRegion = [EVEDBMapRegion mapRegionWithRegionID:order.regionID error:nil];
					region = [NSDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], @"orders", mapRegion.regionName, @"region", nil];
					[buyOrdersRegionsDic setValue:region forKey:regionID];
				}
				NSMutableArray *orders = [region valueForKey:@"orders"];
				[orders addObject:order];
			}
			
			[sellOrdersRegionsTmp addObjectsFromArray:[[sellOrdersRegionsDic allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"region" ascending:YES]]]];
			[buyOrdersRegionsTmp addObjectsFromArray:[[buyOrdersRegionsDic allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"region" ascending:YES]]]];
			
			
			[sellSummaryTmp addObjectsFromArray:quickLook.sellOrders];
			[buySummaryTmp addObjectsFromArray:quickLook.buyOrders];
		}
		operation.progress = 1;
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		self.sellOrdersRegions = sellOrdersRegionsTmp;
		self.buyOrdersRegions = buyOrdersRegionsTmp;
		self.sellSummary = sellSummaryTmp;
		self.buySummary = buySummaryTmp;
		[ordersTableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}


- (void) searchWithSearchString:(NSString*) aSearchString {
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *filteredSellOrdersRegionsTmp = [NSMutableArray array];
	NSMutableArray *filteredBuyOrdersRegionsTmp = [NSMutableArray array];
	NSMutableArray *filteredSellSummaryTmp = [NSMutableArray array];
	NSMutableArray *filteredBuySummaryTmp = [NSMutableArray array];

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketInfoViewController+Filter" name:@"Searching..."];
	[operation addExecutionBlock:^(void) {
		if ([operation isCancelled])
			return;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		for (NSDictionary *item in sellOrdersRegions) {
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
		operation.progress = 0.25;
		
		for (NSDictionary *item in buyOrdersRegions) {
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
		operation.progress = 0.5;
		for (EVECentralQuickLookOrder *order in sellSummary) {
			if ([order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
				(order.region && [order.region.regionName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
				[filteredSellSummaryTmp addObject:order];
			}
		}
		operation.progress = 0.75;
		for (EVECentralQuickLookOrder *order in buySummary) {
			if ([order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
				(order.region && [order.region.regionName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
				[filteredBuySummaryTmp addObject:order];
			}
		}
		operation.progress = 1;
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			[filteredSellOrdersRegions release];
			[filteredBuyOrdersRegions release];
			[filteredSellSummary release];
			[filteredBuySummary release];
			filteredSellOrdersRegions = [filteredSellOrdersRegionsTmp retain];
			filteredBuyOrdersRegions = [filteredBuyOrdersRegionsTmp retain];
			filteredSellSummary = [filteredSellSummaryTmp retain];
			filteredBuySummary = [filteredBuySummaryTmp retain];
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}


/*- (void) searchWithSearchString:(NSString*) searchString {
	[filteredSellOrdersRegions removeAllObjects];
	[filteredBuyOrdersRegions removeAllObjects];
	[filteredSellSummary removeAllObjects];
	[filteredBuySummary removeAllObjects];
	if (searchString.length < 2)
		return;
	
	for (NSDictionary *item in sellOrdersRegions) {
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
			[filteredSellOrdersRegions addObject:region];
	}

	for (NSDictionary *item in buyOrdersRegions) {
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
			[filteredBuyOrdersRegions addObject:region];
	}
	
	for (EVECentralQuickLookOrder *order in sellSummary) {
		if ([order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
			(order.region && [order.region.regionName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
			[filteredSellSummary addObject:order];
		}
	}

	for (EVECentralQuickLookOrder *order in buySummary) {
		if ([order.stationName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
			(order.region && [order.region.regionName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
			[filteredBuySummary addObject:order];
		}
	}
	
}*/

@end