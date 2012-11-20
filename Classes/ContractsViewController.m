//
//  ContractsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ContractsViewController.h"
#import "EVEOnlineAPI.h"
#import "EVEDBAPI.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "SelectCharacterBarButtonItem.h"
#import "UIAlertView+Error.h"
#import "ContractCellView.h"
#import "ContractViewController.h"
#import "NSString+TimeLeft.h"

@interface ContractsViewController(Private)
- (void) reloadContracts;
- (NSDictionary*) conquerableStations;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
- (IBAction) onClose:(id) sender;
@end

@implementation ContractsViewController
@synthesize contractsTableView;
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
	self.title = @"Contracts";
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:searchBar] autorelease]];
		[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:ownerSegmentControl] autorelease]];
		self.filterPopoverController = [[[UIPopoverController alloc] initWithContentViewController:filterNavigationViewController] autorelease];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
	}
	else
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
	
	ownerSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsContractsOwner];

	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	[self reloadContracts];
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
	self.contractsTableView = nil;
	self.ownerSegmentControl = nil;
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	[contracts release];
	[charContracts release];
	[corpContracts release];
	[filteredValues release];
	[conquerableStations release];
	[charFilter release];
	[corpFilter release];
	contracts = charContracts = corpContracts = filteredValues = nil;
	conquerableStations = nil;
	charFilter = corpFilter = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[contractsTableView release];
	[ownerSegmentControl release];
	[searchBar release];
	[filteredValues release];
	[contracts release];
	[charContracts release];
	[corpContracts release];
	[conquerableStations release];
	[filterViewController release];
	[filterNavigationViewController release];
	[filterPopoverController release];
	[charFilter release];
	[corpFilter release];
    [super dealloc];
}

- (IBAction) onChangeOwner:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:ownerSegmentControl.selectedSegmentIndex forKey:SettingsContractsOwner];
	[self reloadContracts];
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
		return contracts.count;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"ContractCellView";
	
    ContractCellView *cell = (ContractCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSString *nibName;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			nibName = tableView == contractsTableView ? @"ContractCellView" : @"ContractCellViewCompact";
		else
			nibName = @"ContractCellView";
		
        cell = [ContractCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *contractDic;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		contractDic = [filteredValues objectAtIndex:indexPath.row];
	else {
		contractDic = [contracts objectAtIndex:indexPath.row];
	}
	EVEContractsItem *contract = [contractDic valueForKey:@"contract"];
	
	cell.statusLabel.text = [contractDic valueForKey:@"remains"];
	cell.statusLabel.textColor = [contractDic valueForKey:@"remainsColor"];
	cell.typeLabel.text = [contractDic valueForKey:@"typeString"];
	cell.titleLabel.text = contract.title.length > 0 ? contract.title : @"No title";
	cell.locationLabel.text = [contractDic valueForKey:@"location"];
	cell.characterLabel.text = [contractDic valueForKey:@"issuerName"];
	cell.startTimeLabel.text = [contractDic valueForKey:@"dateIssued"];
	cell.priceLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:contract.reward > 0 ? contract.reward : contract.price] numberStyle:NSNumberFormatterDecimalStyle]];
	cell.priceTitleLabel.text = contract.reward > 0 ? @"Reward:" : @"Price:";
	cell.buyoutLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:contract.buyout] numberStyle:NSNumberFormatterDecimalStyle]];
	
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
		return tableView == contractsTableView ? 71 : 123;
	else
		return 123;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	ContractViewController *controller = [[ContractViewController alloc] initWithNibName:@"ContractViewController" bundle:nil];
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
		controller.contract = [[filteredValues objectAtIndex:indexPath.row] valueForKeyPath:@"contract"];
	else
		controller.contract = [[contracts objectAtIndex:indexPath.row] valueForKeyPath:@"contract"];
	controller.corporate = ownerSegmentControl.selectedSegmentIndex == 1;

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[controller.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)] autorelease]];
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
	[self reloadContracts];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

@end

@implementation ContractsViewController(Private)

- (void) reloadContracts {
	
	BOOL corporate = (ownerSegmentControl.selectedSegmentIndex == 1);
	NSMutableArray *currentContracts = corporate ? corpContracts : charContracts;
	EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"contractsFilter" ofType:@"plist"]]];
	
	[contracts release];
	contracts = nil;
	if (!currentContracts) {
		if (corporate) {
			corpContracts = [[NSMutableArray alloc] init];
			currentContracts = corpContracts;
		}
		else {
			charContracts = [[NSMutableArray alloc] init];
			currentContracts = charContracts;
		}
		EVEAccount *account = [EVEAccount currentAccount];
		__block EUOperation *operation = [EUOperation operationWithIdentifier:[NSString stringWithFormat:@"ContractsViewController+Load%d", corporate] name:@"Loading Contracts"];
		NSMutableArray *contractsTmp = [NSMutableArray array];
		
		[operation addExecutionBlock:^(void) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSError *error = nil;
			
			if (!account) {
				[pool release];
				return;
			}
			
			EVEContracts *eveContracts;
			if (corporate)
				eveContracts = [EVEContracts contractsWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID corporate:corporate error:&error];
			else
				eveContracts = [EVEContracts contractsWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID corporate:corporate error:&error];
			operation.progress = 0.5;
			if (error) {
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			}
			else {
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
				//NSMutableDictionary *characters = [NSMutableDictionary dictionary];
				NSMutableSet* charIDs = [NSMutableSet set];
				
				NSDate *currentTime = [eveContracts serverTimeWithLocalTime:[NSDate date]];
				float n = eveContracts.contractList.count;
				float i = 0;
				for (EVEContractsItem *contract in eveContracts.contractList) {
					operation.progress = 0.5 + i++ / n / 2;
					NSString *remains;
					UIColor *remainsColor;
					NSString *stationName = nil;
					
					EVEDBStaStation *station = [EVEDBStaStation staStationWithStationID:contract.startStationID error:nil];
					
					if (!station) {
						EVEConquerableStationListItem *conquerableStation = [[self conquerableStations] valueForKey:[NSString stringWithFormat:@"%d", contract.startStationID]];
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
					
					NSString *statusString = [contract localizedStatusString];
					if (contract.status <= EVEContractStatusCompletedByContractor) {
						remains = [NSString stringWithFormat:@"Completed: %@", [dateFormatter stringFromDate:contract.dateCompleted]];
						remainsColor = [UIColor greenColor];
					}
					else if (contract.status >= EVEContractStatusCancelled) {
						remains = statusString;
						remainsColor = [UIColor redColor];
					}
					else {
						NSTimeInterval remainsTime = [contract.dateExpired timeIntervalSinceDate:currentTime];
						if (remainsTime > 0)
							remains = [NSString stringWithFormat:@"%@: %@", statusString, [NSString stringWithTimeLeft:remainsTime]];
						else
							remains = statusString;
						remainsColor = [UIColor yellowColor];
					}
					
					
					[charIDs addObject:[NSString stringWithFormat:@"%d", contract.issuerID]];
					if (contract.assigneeID > 0)
						[charIDs addObject:[NSString stringWithFormat:@"%d", contract.assigneeID]];
					
					[contractsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
											 remains, @"remains",
											 stationName, @"location",
											 remainsColor, @"remainsColor",
											 contract, @"contract",
											 statusString, @"statusString",
											 [contract localizedTypeString], @"typeString",
											 [dateFormatter stringFromDate:contract.dateIssued], @"dateIssued",
											 nil]];
				}
				[dateFormatter release];
				
				[contractsTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"dateIssued" ascending:NO]]];
				
				if (charIDs.count > 0) {
					NSError *error = nil;
					EVECharacterName *characterNames = [EVECharacterName characterNameWithIDs:[charIDs allObjects] error:&error];
					if (!error) {
						for (NSMutableDictionary *item in contractsTmp) {
							EVEContractsItem *contract = [item valueForKey:@"contract"];
							if (contract.issuerID) {
								NSString *charName = [characterNames.characters valueForKey:[NSString stringWithFormat:@"%d", contract.issuerID]];
								if (!charName)
									charName = @"";
								[item setValue:charName forKey:@"issuerName"];
							}
							if (contract.assigneeID) {
								NSString *charName = [characterNames.characters valueForKey:[NSString stringWithFormat:@"%d", contract.assigneeID]];
								if (!charName)
									charName = @"";
								[item setValue:charName forKey:@"assigneeName"];
							}
						}
					}
				}
				
				[filterTmp updateWithValues:contractsTmp];
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
				[currentContracts addObjectsFromArray:contractsTmp];
				if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate)
					[self reloadContracts];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		EUFilter *filter = corporate ? corpFilter : charFilter;
		NSMutableArray *contractsTmp = [NSMutableArray array];
		if (filter) {
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ContractsViewController+Filter" name:@"Applying Filter"];
			[operation addExecutionBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				[contractsTmp addObjectsFromArray:[filter applyToValues:currentContracts]];
				[pool release];
			}];
			
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![operation isCancelled]) {
					if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						[contracts release];
						contracts = [contractsTmp retain];
						[self searchWithSearchString:self.searchBar.text];
						[contractsTableView reloadData];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else
			contracts = [currentContracts retain];
	}
	[contractsTableView reloadData];
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
	if (!account) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[contracts release];
			[charContracts release];
			[corpContracts release];
			[filteredValues release];
			contracts = charContracts = corpContracts = filteredValues = nil;
			[charFilter release];
			[corpFilter release];
			charFilter = corpFilter = nil;
			[self reloadContracts];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		[contracts release];
		[charContracts release];
		[corpContracts release];
		[filteredValues release];
		contracts = charContracts = corpContracts = filteredValues = nil;
		[charFilter release];
		[corpFilter release];
		charFilter = corpFilter = nil;
		[self reloadContracts];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (contracts.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ContractsViewController+Search" name:@"Searcing..."];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		for (NSDictionary *contract in contracts) {
			if (([contract valueForKeyPath:@"remains"] && [[contract valueForKeyPath:@"remains"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([contract valueForKeyPath:@"location"] && [[contract valueForKeyPath:@"location"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([contract valueForKeyPath:@"issuerName"] && [[contract valueForKeyPath:@"issuerName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([contract valueForKeyPath:@"dateIssued"] && [[contract valueForKeyPath:@"dateIssued"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([contract valueForKeyPath:@"contract.title"] && [[contract valueForKeyPath:@"contract.title"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([contract valueForKeyPath:@"typeString"] && [[contract valueForKeyPath:@"typeString"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
				[filteredValuesTmp addObject:contract];
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

- (IBAction) onClose:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

@end