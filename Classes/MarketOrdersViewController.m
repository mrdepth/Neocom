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

@interface MarketOrdersViewController()
@property (nonatomic, strong) NSMutableArray *filteredValues;
@property (nonatomic, strong) NSMutableArray *orders;
@property (nonatomic, strong) NSMutableArray *charOrders;
@property (nonatomic, strong) NSMutableArray *corpOrders;
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
	[self.tableView setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]]];
	
	self.navigationItem.titleView = self.ownerSegmentControl;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.searchBar]];
		self.filterPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.filterNavigationViewController];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
	}
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

- (void)viewDidUnload {
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.ownerSegmentControl = nil;
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	self.orders = nil;
	self.charOrders = nil;
	self.corpOrders = nil;
	self.filteredValues = nil;
	self.conquerableStations = nil;
	self.charFilter = nil;
	self.corpFilter = nil;
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
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return self.filteredValues.count;
	else {
		return self.orders.count;
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
		order = [self.orders objectAtIndex:indexPath.row];
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
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source.
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return tableView == self.tableView ? 70 : 104;
	else
		return 104;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
		controller.type = [[self.filteredValues objectAtIndex:indexPath.row] valueForKey:@"type"];
	else
		controller.type = [[self.orders objectAtIndex:indexPath.row] valueForKey:@"type"];
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:navController animated:YES];
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
	tableView.backgroundColor = [UIColor clearColor];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundPopover~ipad.png"]];
		tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	else
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)aSearchBar {
	BOOL corporate = (self.ownerSegmentControl.selectedSegmentIndex == 1);
	EUFilter *filter = corporate ? self.corpFilter : self.charFilter;
	self.filterViewController.filter = filter;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.filterPopoverController presentPopoverFromRect:self.searchBar.frame inView:[self.searchBar superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	else
		[self presentModalViewController:self.filterNavigationViewController animated:YES];
}

#pragma mark FilterViewControllerDelegate
- (void) filterViewController:(FilterViewController*) controller didApplyFilter:(EUFilter*) filter {
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		[self dismissModalViewControllerAnimated:YES];
	[self reloadOrders];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private

- (void) reloadOrders {
	BOOL corporate = (self.ownerSegmentControl.selectedSegmentIndex == 1);
	NSMutableArray *currentOrders = corporate ? self.corpOrders : self.charOrders;
	EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"marketOrdersFilter" ofType:@"plist"]]];
	
	self.orders = nil;
	if (!currentOrders) {
		if (corporate) {
			self.corpOrders = [[NSMutableArray alloc] init];
			currentOrders = self.corpOrders;
		}
		else {
			self.charOrders = [[NSMutableArray alloc] init];
			currentOrders = self.charOrders;
		}
		
		EVEAccount *account = [EVEAccount currentAccount];
		
		__block EUOperation *operation = [EUOperation operationWithIdentifier:[NSString stringWithFormat:@"MarketOrdersViewController+Load%d", corporate] name:NSLocalizedString(@"Loading Market Orders", nil)];
		__weak EUOperation* weakOperation = operation;
		NSMutableArray *ordersTmp = [NSMutableArray array];

		[operation addExecutionBlock:^(void) {
			NSError *error = nil;

			if (!account) {
				return;
			}

			EVEMarketOrders *marketOrders;
			if (corporate)
				marketOrders = [EVEMarketOrders marketOrdersWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID corporate:corporate error:&error progressHandler:nil];
			else
				marketOrders = [EVEMarketOrders marketOrdersWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID corporate:corporate error:&error progressHandler:nil];
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
					NSString *expireIn;
					NSString *volEntered = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:order.volEntered] numberStyle:NSNumberFormatterDecimalStyle];
					NSString *volRemaining = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:order.volRemaining] numberStyle:NSNumberFormatterDecimalStyle];
					NSString *state;
					UIColor *stateColor;
					EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:order.typeID error:nil];//[[EVEDBInvType alloc] initWithTypeID:order.typeID error:nil];
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
					
					[ordersTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										  expireIn, @"expireIn",
										  orderType, @"orderType",
										  state, @"state",
										  stateColor, @"stateColor",
										  stationName, @"stationName",
										  [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:order.price] numberStyle:NSNumberFormatterDecimalStyle]], @"price",
										  [NSString stringWithFormat:@"%@ / %@", volRemaining, volEntered], @"qty",
										  [dateFormatter stringFromDate:order.issued], @"issued",
										  [type typeSmallImageName], @"imageName",
										  charID, @"charID",
										  @"", @"characterName",
										  [NSNumber numberWithBool:!order.bid], @"sell",
										  [NSNumber numberWithBool:order.orderState == EVEOrderStateOpen], @"active",
										  type, @"type",
										  type.typeName, @"typeName",
										  nil
										  ]];
				}
				weakOperation.progress = 0.75;
				[ordersTmp sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"active" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"issued" ascending:NO], nil]];
				
				if (charIDs.count > 0) {
					NSError *error = nil;
					EVECharacterName *characterNames = [EVECharacterName characterNameWithIDs:[charIDs allObjects] error:&error progressHandler:nil];
					if (!error) {
						for (NSDictionary *order in ordersTmp) {
							NSString *charID = [order valueForKey:@"charID"];
							NSString *charName = [characterNames.characters valueForKey:charID];
							if (!charName)
								charName = @"";
							[order setValue:charName forKey:@"characterName"];
						}
					}
				}
				[filterTmp updateWithValues:ordersTmp];
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
				[currentOrders addObjectsFromArray:ordersTmp];
				if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate)
					[self reloadOrders];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		EUFilter *filter = corporate ? self.corpFilter : self.charFilter;
		NSMutableArray *ordersTmp = [NSMutableArray array];
		if (filter) {
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketOrdersViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				[ordersTmp addObjectsFromArray:[filter applyToValues:currentOrders]];
			}];
			
			[operation setCompletionBlockInMainThread:^(void) {
				if (![weakOperation isCancelled]) {
					if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						self.orders = ordersTmp;
						[self searchWithSearchString:self.searchBar.text];
						[self.tableView reloadData];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else
			self.orders = currentOrders;
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
			self.orders = nil;
			self.charOrders = nil;
			self.corpOrders = nil;
			self.filteredValues = nil;
			self.charFilter = nil;
			self.corpFilter = nil;
			[self reloadOrders];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	else {
		self.orders = nil;
		self.charOrders = nil;
		self.corpOrders = nil;
		self.filteredValues = nil;
		self.charFilter = nil;
		self.corpFilter = nil;
		[self reloadOrders];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (self.orders.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MarketOrdersViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		for (NSDictionary *order in self.orders) {
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
