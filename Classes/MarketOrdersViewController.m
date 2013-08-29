//
//  MarketOrdersViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MarketOrdersViewController.h"
#import "EVEOnlineAPI.h"
#import "UIAlertView+Error.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "MarketOrderCellView.h"
#import "UITableViewCell+Nib.h"
#import "SelectCharacterBarButtonItem.h"
#import "ItemViewController.h"
#import "NSString+TimeLeft.h"
#import "appearance.h"
#import "NSNumberFormatter+Neocom.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "UIViewController+Neocom.h"

@interface MarketOrdersViewController()
@property (nonatomic, strong) NSMutableArray *filteredValues;
@property (nonatomic, strong) NSMutableArray *openOrders;
@property (nonatomic, strong) NSMutableArray *closedOrders;
@property (nonatomic, strong) NSMutableArray *charOpenOrders;
@property (nonatomic, strong) NSMutableArray *charClosedOrders;
@property (nonatomic, strong) NSMutableArray *corpOpenOrders;
@property (nonatomic, strong) NSMutableArray *corpClosedOrders;
@property (nonatomic, strong) NSMutableDictionary *conquerableStations;
@property (nonatomic, strong) EUFilter *charFilter;
@property (nonatomic, strong) EUFilter *corpFilter;

- (void) reloadOrders;
- (void) searchWithSearchString:(NSString*) searchString;

@end

@implementation MarketOrdersViewController

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	
	self.navigationItem.titleView = self.ownerSegmentControl;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.searchBar]];
	else
		self.tableView.tableHeaderView = self.searchBar;
	
	self.ownerSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsMarketOrdersOwner];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:EVEAccountDidSelectNotification object:nil];
	[self reloadOrders];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction) onChangeOwner:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:self.ownerSegmentControl.selectedSegmentIndex forKey:SettingsMarketOrdersOwner];
	[self reloadOrders];
}

- (IBAction) onChangeOrderType:(id) sender {
	[self reloadOrders];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return self.searchDisplayController.searchResultsTableView == tableView ? 1 : 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return self.filteredValues.count;
	else {
		return section == 0 ? self.openOrders.count : self.closedOrders.count;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"MarketOrderCellView";

    MarketOrderCellView *cell = (MarketOrderCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSString *nibName;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			nibName = tableView == self.tableView ? @"MarketOrderCellView" : @"MarketOrderCellViewCompact";
		else
			nibName = @"MarketOrderCellView";
		
        cell = [MarketOrderCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *order;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		order = [self.filteredValues objectAtIndex:indexPath.row];
	else {
		order = indexPath.section == 0 ? self.openOrders[indexPath.row] : self.closedOrders[indexPath.row];
	}
	
	cell.expireInLabel.text = [order valueForKey:@"expireIn"];

	cell.stateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ order: %@", nil), [order valueForKey:@"orderType"], [order valueForKey:@"state"]];
	cell.typeNameLabel.text = [order valueForKey:@"typeName"];
	cell.locationLabel.text = [order valueForKey:@"stationName"];
	cell.priceLabel.text = [order valueForKey:@"price"];
	cell.qtyLabel.text = [order valueForKey:@"qty"];
	cell.issuedLabel.text = [order valueForKey:@"issued"];
	cell.characterLabel.text = [order valueForKey:@"characterName"];
	cell.iconImageView.image = [UIImage imageNamed:[order valueForKey:@"imageName"]];
	cell.stateLabel.textColor = [order valueForKey:@"stateColor"];
    
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return nil;
	else
		return section == 0 ? [NSString stringWithFormat:NSLocalizedString(@"Open orders (%d)", nil), self.openOrders.count] : NSLocalizedString(@"Closed Orders", nil);
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return tableView == self.tableView ? 75 : 109;
	else
		return 109;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
		controller.type = self.filteredValues[indexPath.row][@"type"];
	else
		controller.type = indexPath.section == 0 ? self.openOrders[indexPath.row][@"type"] : self.closedOrders[indexPath.row][@"type"];
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentViewController:navController animated:YES completion:nil];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

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
	EUFilter *filter = corporate ? self.corpFilter : self.charFilter;
	self.filterViewController.filter = filter;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self presentViewControllerInPopover:self.filterNavigationViewController
									fromRect:self.searchBar.frame
									  inView:[self.searchBar superview]
					permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	else
		[self presentViewController:self.filterNavigationViewController animated:YES completion:nil];
}

#pragma mark FilterViewControllerDelegate
- (void) filterViewController:(FilterViewController*) controller didApplyFilter:(EUFilter*) filter {
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		[self dismissViewControllerAnimated:YES completion:nil];
	[self reloadOrders];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void) reloadOrders {
	BOOL corporate = (self.ownerSegmentControl.selectedSegmentIndex == 1);
	NSMutableArray *currentOpenOrders = corporate ? self.corpOpenOrders : self.charOpenOrders;
	NSMutableArray *currentClosedOrders = corporate ? self.corpClosedOrders : self.charClosedOrders;
	EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"marketOrdersFilter" ofType:@"plist"]]];
	
	self.openOrders = nil;
	self.closedOrders = nil;
	if (!currentOpenOrders || !currentClosedOrders) {
		EVEAccount *account = [EVEAccount currentAccount];
		if (corporate) {
			self.corpOpenOrders = [[NSMutableArray alloc] init];
			self.corpClosedOrders = [[NSMutableArray alloc] init];
			currentOpenOrders = self.corpOpenOrders;
			currentClosedOrders = self.corpClosedOrders;
			if (!account.corpAPIKey) {
				[self.tableView reloadData];
				return;
			}
		}
		else {
			self.charOpenOrders = [[NSMutableArray alloc] init];
			self.charClosedOrders = [[NSMutableArray alloc] init];
			currentOpenOrders = self.charOpenOrders;
			currentClosedOrders = self.charClosedOrders;
		}
		
		
		EUOperation *operation = [EUOperation operationWithIdentifier:[NSString stringWithFormat:@"MarketOrdersViewController+Load%d", corporate] name:NSLocalizedString(@"Loading Market Orders", nil)];
		__weak EUOperation* weakOperation = operation;
		NSMutableArray *openOrdersTmp = [NSMutableArray array];
		NSMutableArray *closedOrdersTmp = [NSMutableArray array];

		[operation addExecutionBlock:^(void) {
			NSError *error = nil;

			if (!account) {
				return;
			}

			EVEMarketOrders *marketOrders;
			if (corporate)
				marketOrders = [EVEMarketOrders marketOrdersWithKeyID:account.corpAPIKey.keyID vCode:account.corpAPIKey.vCode characterID:account.character.characterID corporate:corporate error:&error progressHandler:nil];
			else
				marketOrders = [EVEMarketOrders marketOrdersWithKeyID:account.charAPIKey.keyID vCode:account.charAPIKey.vCode characterID:account.character.characterID corporate:corporate error:&error progressHandler:nil];
			weakOperation.progress = 0.5;
			
			NSDate *currentTime = [marketOrders serverTimeWithLocalTime:[NSDate date]];
			
			if (error) {
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			}
			else {
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
				[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
				NSMutableSet *charIDs = [NSMutableSet set];
				
				for (EVEMarketOrdersItem *order in marketOrders.orders) {
					if (order.duration == 0)
						continue;
					
					NSString *expireIn;
					NSString *volEntered = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:order.volEntered] numberStyle:NSNumberFormatterDecimalStyle];
					NSString *volRemaining = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:order.volRemaining] numberStyle:NSNumberFormatterDecimalStyle];
					NSString *state;
					UIColor *stateColor;
					EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:order.typeID error:nil];
					NSString *stationName = nil;
					NSString *charID = [NSString stringWithFormat:@"%d", order.charID];
					EVEDBStaStation *station = [EVEDBStaStation staStationWithStationID:order.stationID error:nil];
					
					if (!station) {
						EVEConquerableStationListItem *conquerableStation = self.conquerableStations[@(order.stationID)];
						if (conquerableStation) {
							EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID error:nil];
							if (solarSystem)
								stationName = [NSString stringWithFormat:@"%@ / %@", conquerableStation.stationName, solarSystem.solarSystemName];
							else
								stationName = conquerableStation.stationName;
						}
						else
							stationName = NSLocalizedString(@"Unknown Location", nil);
					}
					else
						stationName = [NSString stringWithFormat:@"%@ / %@", station.stationName, station.solarSystem.solarSystemName];
					
					switch (order.orderState) {
						case EVEOrderStateOpen:
							state = NSLocalizedString(@"Open", nil);
							stateColor = [UIColor greenColor];
							break;
						case EVEOrderStateCancelled:
							state = NSLocalizedString(@"Cancelled", nil);
							stateColor = [UIColor redColor];
							break;
						case EVEOrderStateCharacterDeleted:
							state = NSLocalizedString(@"Deleted", nil);
							stateColor = [UIColor redColor];
							break;
						case EVEOrderStateClosed:
							state = NSLocalizedString(@"Closed", nil);
							stateColor = [UIColor redColor];
							break;
						case EVEOrderStateExpired:
							if (order.duration > 1) {
								state = NSLocalizedString(@"Expired", nil);
								stateColor = [UIColor redColor];
							}
							else {
								state = NSLocalizedString(@"Fulfilled", nil);
								stateColor = [UIColor greenColor];
							}
							break;
						case EVEOrderStatePending:
							state = NSLocalizedString(@"Pending", nil);
							stateColor = [UIColor yellowColor];
							break;
						default:
							break;
					}
					
					NSDate *endTime = [order.issued dateByAddingTimeInterval:order.duration * 24 * 3600];
					NSTimeInterval expireInTime = [endTime timeIntervalSinceDate:currentTime];
					
					if (expireInTime > 0)
						expireIn = [NSString stringWithTimeLeft:expireInTime componentsLimit:2];
					else
						expireIn = NSLocalizedString(@"Expired", nil);
					
					[charIDs addObject:charID];
					
					NSString *orderType = order.bid ? NSLocalizedString(@"Buy", nil) : NSLocalizedString(@"Sell", nil);
					
					NSDictionary* record = @{@"order" : order,
							  @"timeLeft": @(expireInTime),
							  @"expireIn": expireIn,
							  @"orderType": orderType ,
							  @"state": state,
							  @"stateColor": stateColor,
							  @"stationName": stationName,
							  @"price": [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(order.price)]],
							  @"qty": [NSString stringWithFormat:@"%@ / %@", volRemaining, volEntered],
							  @"issued": [dateFormatter stringFromDate:order.issued],
							  @"imageName": [type typeSmallImageName],
							  @"charID": charID,
							  @"characterName": @"",
							  @"sell": @(order.bid),
							  @"active": @(order.orderState == EVEOrderStateOpen),
							  @"type": type,
							  @"typeName": type.typeName,
							  @"order": order};
					if (order.orderState == EVEOrderStateOpen)
						[openOrdersTmp addObject:[NSMutableDictionary dictionaryWithDictionary:record]];
					else
						[closedOrdersTmp addObject:[NSMutableDictionary dictionaryWithDictionary:record]];
				}
				weakOperation.progress = 0.75;
				//[ordersTmp sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"active" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"issued" ascending:NO], nil]];
				[openOrdersTmp sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timeLeft" ascending:YES]]];
				[closedOrdersTmp sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timeLeft" ascending:NO]]];
				
				if (charIDs.count > 0) {
					NSError *error = nil;
					EVECharacterName *characterNames = [EVECharacterName characterNameWithIDs:[charIDs allObjects] error:&error progressHandler:nil];
					if (!error) {
						for (NSArray* orders in @[openOrdersTmp, closedOrdersTmp]) {
							for (NSDictionary *order in orders) {
								NSString *charID = [order valueForKey:@"charID"];
								NSString *charName = [characterNames.characters valueForKey:charID];
								if (!charName)
									charName = @"";
								[order setValue:charName forKey:@"characterName"];
							}
						}
					}
				}
				[filterTmp updateWithValues:openOrdersTmp];
				[filterTmp updateWithValues:closedOrdersTmp];
				weakOperation.progress = 1.0;
			}
		}];
		
		[operation setCompletionBlockInMainThread:^(void) {
			if (![weakOperation isCancelled]) {
				if (corporate) {
					self.corpFilter = filterTmp;
				}
				else {
					self.charFilter = filterTmp;
				}
				[currentOpenOrders addObjectsFromArray:openOrdersTmp];
				[currentClosedOrders addObjectsFromArray:closedOrdersTmp];
				if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate)
					[self reloadOrders];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		EUFilter *filter = corporate ? self.corpFilter : self.charFilter;
		NSMutableArray *openOrdersTmp = [NSMutableArray array];
		NSMutableArray *closedOrdersTmp = [NSMutableArray array];
		if (filter) {
			EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketOrdersViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				[openOrdersTmp addObjectsFromArray:[filter applyToValues:currentOpenOrders]];
				[closedOrdersTmp addObjectsFromArray:[filter applyToValues:currentClosedOrders]];
			}];
			
			[operation setCompletionBlockInMainThread:^(void) {
				if (![weakOperation isCancelled]) {
					if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						self.openOrders = openOrdersTmp;
						self.closedOrders = closedOrdersTmp;
						[self searchWithSearchString:self.searchBar.text];
						[self.tableView reloadData];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			self.openOrders = currentOpenOrders;
			self.closedOrders = currentClosedOrders;
		}
	}
	[self.tableView reloadData];
}

- (NSMutableDictionary*) conquerableStations {
	if (!_conquerableStations) {
		@autoreleasepool {
			_conquerableStations = [[NSMutableDictionary alloc] init];
			
			NSError *error = nil;
			EVEConquerableStationList *stationsList = [EVEConquerableStationList conquerableStationListWithError:&error progressHandler:nil];
			
			if (!error) {
				for (EVEConquerableStationListItem *station in stationsList.outposts)
					_conquerableStations[@(station.stationID)] = station;
			}
		}
	}
	return _conquerableStations;
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	if (!account)
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.openOrders = nil;
			self.closedOrders = nil;
			self.charOpenOrders = nil;
			self.charClosedOrders = nil;
			self.corpOpenOrders = nil;
			self.corpClosedOrders = nil;
			self.filteredValues = nil;
			self.charFilter = nil;
			self.corpFilter = nil;
			[self reloadOrders];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	else {
		self.openOrders = nil;
		self.closedOrders = nil;
		self.charOpenOrders = nil;
		self.charClosedOrders = nil;
		self.corpOpenOrders = nil;
		self.corpClosedOrders = nil;
		self.filteredValues = nil;
		self.charFilter = nil;
		self.corpFilter = nil;
		[self reloadOrders];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if ((self.openOrders.count == 0 && self.closedOrders.count == 0) || !aSearchString)
		return;
	
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketOrdersViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NSMutableArray* orders = [NSMutableArray arrayWithArray:self.openOrders];
		[orders addObjectsFromArray:self.closedOrders];
		for (NSDictionary *order in orders) {
			if ([weakOperation isCancelled])
				 break;
			if (([order valueForKey:@"typeName"] && [[order valueForKey:@"typeName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([order valueForKey:@"stationName"] && [[order valueForKey:@"stationName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([order valueForKey:@"characterName"] && [[order valueForKey:@"characterName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([order valueForKey:@"state"] && [[order valueForKey:@"state"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([order valueForKey:@"issued"] && [[order valueForKey:@"issued"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
				[filteredValuesTmp addObject:order];
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

@end
