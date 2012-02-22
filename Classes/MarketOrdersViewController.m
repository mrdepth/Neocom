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
#import "NibTableViewCell.h"
#import "SelectCharacterBarButtonItem.h"
#import "ItemViewController.h"
#import "NSString+TimeLeft.h"

@interface MarketOrdersViewController(Private)
- (void) reloadOrders;
- (NSDictionary*) conquerableStations;
- (void) searchWithSearchString:(NSString*) searchString;
@end

@implementation MarketOrdersViewController
@synthesize marketOrdersTableView;
@synthesize ownerSegmentControl;
@synthesize searchBar;
@synthesize filterViewController;
@synthesize filterNavigationViewController;
@synthesize filterPopoverController;

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
	self.title = @"Market Orders";
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:searchBar] autorelease]];
		[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:ownerSegmentControl] autorelease]];
		self.filterPopoverController = [[[UIPopoverController alloc] initWithContentViewController:filterNavigationViewController] autorelease];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
	}
	else
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
	
	ownerSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsMarketOrdersOwner];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	[self reloadOrders];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	self.marketOrdersTableView = nil;
	self.ownerSegmentControl = nil;
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	[orders release];
	[charOrders release];
	[corpOrders release];
	[filteredValues release];
	[conquerableStations release];
	[charFilter release];
	[corpFilter release];

	orders = charOrders = corpOrders = filteredValues = nil;
	conquerableStations = nil;
	charFilter = corpFilter = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[marketOrdersTableView release];
	[ownerSegmentControl release];
	[searchBar release];
	[orders release];
	[charOrders release];
	[corpOrders release];
	[filteredValues release];
	[conquerableStations release];
	[filterViewController release];
	[filterNavigationViewController release];
	[filterPopoverController release];
	[charFilter release];
	[corpFilter release];
    [super dealloc];
}

- (IBAction) onChangeOwner:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:ownerSegmentControl.selectedSegmentIndex forKey:SettingsMarketOrdersOwner];
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
		return filteredValues.count;
	else {
		return orders.count;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"MarketOrderCellView";

    MarketOrderCellView *cell = (MarketOrderCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSString *nibName;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			nibName = tableView == marketOrdersTableView ? @"MarketOrderCellView-iPad" : @"MarketOrderCellView";
		else
			nibName = @"MarketOrderCellView";
		
        cell = [MarketOrderCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *order;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		order = [filteredValues objectAtIndex:indexPath.row];
	else {
		order = [orders objectAtIndex:indexPath.row];
	}
	
	cell.expireInLabel.text = [order valueForKey:@"expireIn"];

	cell.stateLabel.text = [NSString stringWithFormat:@"%@ order: %@", [order valueForKey:@"orderType"], [order valueForKey:@"state"]];
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
		return tableView == marketOrdersTableView ? 70 : 104;
	else
		return 104;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemViewController-iPad" : @"ItemViewController")
																		  bundle:nil];
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
		controller.type = [[filteredValues objectAtIndex:indexPath.row] valueForKey:@"type"];
	else
		controller.type = [[orders objectAtIndex:indexPath.row] valueForKey:@"type"];
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:navController animated:YES];
		[navController release];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
	[controller release];
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
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background4.png"]] autorelease];	
		tableView.backgroundView.contentMode = UIViewContentModeTopLeft;
	}
	else
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]] autorelease];	
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)aSearchBar {
	BOOL corporate = (ownerSegmentControl.selectedSegmentIndex == 1);
	EUFilter *filter = corporate ? corpFilter : charFilter;
	filterViewController.filter = filter;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[filterPopoverController presentPopoverFromRect:searchBar.frame inView:[searchBar superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	else
		[self presentModalViewController:filterNavigationViewController animated:YES];
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

@end

@implementation MarketOrdersViewController(Private)

- (void) reloadOrders {
	BOOL corporate = (ownerSegmentControl.selectedSegmentIndex == 1);
	NSMutableArray *currentOrders = corporate ? corpOrders : charOrders;
	EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"marketOrdersFilter" ofType:@"plist"]]];
	
	[orders release];
	orders = nil;
	if (!currentOrders) {
		if (corporate) {
			corpOrders = [[NSMutableArray alloc] init];
			currentOrders = corpOrders;
		}
		else {
			charOrders = [[NSMutableArray alloc] init];
			currentOrders = charOrders;
		}
		
		EVEAccount *account = [EVEAccount currentAccount];
		
		__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:[NSString stringWithFormat:@"MarketOrdersViewController+Load%d", corporate]];
		NSMutableArray *ordersTmp = [NSMutableArray array];

		[operation addExecutionBlock:^(void) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSError *error = nil;

			if (!account) {
				[pool release];
				return;
			}

			EVEMarketOrders *marketOrders;
			if (corporate)
				marketOrders = [EVEMarketOrders marketOrdersWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID corporate:corporate error:&error];
			else
				marketOrders = [EVEMarketOrders marketOrdersWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID corporate:corporate error:&error];
			
			NSDate *currentTime = [marketOrders serverTimeWithLocalTime:[NSDate date]];
			
			if (error) {
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			}
			else {
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
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
						EVEConquerableStationListItem *conquerableStation = [[self conquerableStations] valueForKey:[NSString stringWithFormat:@"%d", order.stationID]];
						if (conquerableStation) {
							EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID error:nil];
							if (solarSystem)
								stationName = [NSString stringWithFormat:@"%@ / %@", conquerableStation.stationName, solarSystem.solarSystemName];
							else
								stationName = conquerableStation.stationName;
						}
						else
							stationName = @"Unknown";
					}
					else
						stationName = [NSString stringWithFormat:@"%@ / %@", station.stationName, station.solarSystem.solarSystemName];
					
					switch (order.orderState) {
						case EVEOrderStateOpen:
							state = @"Open";
							stateColor = [UIColor greenColor];
							break;
						case EVEOrderStateCancelled:
							state = @"Cancelled";
							stateColor = [UIColor redColor];
							break;
						case EVEOrderStateCharacterDeleted:
							state = @"Deleted";
							stateColor = [UIColor redColor];
							break;
						case EVEOrderStateClosed:
							state = @"Closed";
							stateColor = [UIColor redColor];
							break;
						case EVEOrderStateExpired:
							if (order.duration > 1) {
								state = @"Expired";
								stateColor = [UIColor redColor];
							}
							else {
								state = @"Fulfilled";
								stateColor = [UIColor greenColor];
							}
							break;
						case EVEOrderStatePending:
							state = @"Pending";
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
						expireIn = @"Expired";
					
					[charIDs addObject:charID];
					
					NSString *orderType = order.bid ? @"Buy" : @"Sell";
					
					[ordersTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										  expireIn, @"expireIn",
										  orderType, @"orderType",
										  state, @"state",
										  stateColor, @"stateColor",
										  stationName, @"stationName",
										  [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:order.price] numberStyle:NSNumberFormatterDecimalStyle]], @"price",
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
				[dateFormatter release];
				
				[ordersTmp sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"active" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"issued" ascending:NO], nil]];
				
				if (charIDs.count > 0) {
					NSError *error = nil;
					EVECharacterName *characterNames = [EVECharacterName characterNameWithIDs:[charIDs allObjects] error:&error];
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
			}
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^(void) {
			if (![operation isCancelled]) {
				if (corporate) {
					[corpFilter release];
					corpFilter = [filterTmp retain];
				}
				else {
					[charFilter release];
					charFilter = [filterTmp retain];
				}
				[currentOrders addObjectsFromArray:ordersTmp];
				if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate)
					[self reloadOrders];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		EUFilter *filter = corporate ? corpFilter : charFilter;
		NSMutableArray *ordersTmp = [NSMutableArray array];
		if (filter) {
			__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"MarketOrdersViewController+Filter"];
			[operation addExecutionBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				[ordersTmp addObjectsFromArray:[filter applyToValues:currentOrders]];
				[pool release];
			}];
			
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![operation isCancelled]) {
					if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						[orders release];
						orders = [ordersTmp retain];
						[self searchWithSearchString:self.searchBar.text];
						[marketOrdersTableView reloadData];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else
			orders = [currentOrders retain];
	}
	[marketOrdersTableView reloadData];
}

- (NSDictionary*) conquerableStations {
	if (!conquerableStations) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		if (conquerableStations)
			[conquerableStations release];
		conquerableStations = [[NSMutableDictionary alloc] init];
		
		NSError *error = nil;
		EVEConquerableStationList *stationsList = [EVEConquerableStationList conquerableStationListWithError:&error];
		
		if (!error) {
			for (EVEConquerableStationListItem *station in stationsList.outposts)
				[conquerableStations setValue:station forKey:[NSString stringWithFormat:@"%d", station.stationID]];
		}
		[pool release];
	}
	return conquerableStations;
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	if (!account)
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[orders release];
			[charOrders release];
			[corpOrders release];
			[filteredValues release];
			orders = charOrders = corpOrders = filteredValues = nil;
			[charFilter release];
			[corpFilter release];
			charFilter = corpFilter = nil;
			[self reloadOrders];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	else {
		[orders release];
		[charOrders release];
		[corpOrders release];
		[filteredValues release];
		orders = charOrders = corpOrders = filteredValues = nil;
		[charFilter release];
		[corpFilter release];
		charFilter = corpFilter = nil;
		[self reloadOrders];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (orders.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"MarketOrdersViewController+Search"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		for (NSDictionary *order in orders) {
			if (([order valueForKey:@"typeName"] && [[order valueForKey:@"typeName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([order valueForKey:@"stationName"] && [[order valueForKey:@"stationName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([order valueForKey:@"characterName"] && [[order valueForKey:@"characterName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([order valueForKey:@"state"] && [[order valueForKey:@"state"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([order valueForKey:@"issued"] && [[order valueForKey:@"issued"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
				[filteredValuesTmp addObject:order];
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			[filteredValues release];
			filteredValues = [filteredValuesTmp retain];
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
