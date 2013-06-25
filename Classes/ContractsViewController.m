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

@interface ContractsViewController()
@property(nonatomic, strong) NSMutableArray *filteredValues;
@property(nonatomic, strong) NSMutableArray *contracts;
@property(nonatomic, strong) NSMutableArray *charContracts;
@property(nonatomic, strong) NSMutableArray *corpContracts;
@property(nonatomic, strong) NSMutableDictionary *conquerableStations;
@property(nonatomic, strong) EUFilter *charFilter;
@property(nonatomic, strong) EUFilter *corpFilter;

- (void) reloadContracts;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
- (IBAction) onClose:(id) sender;
@end

@implementation ContractsViewController

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
	self.title = NSLocalizedString(@"Contracts", nil);
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.searchBar]];
		self.navigationItem.titleView = self.ownerSegmentControl;
		self.filterPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.filterNavigationViewController];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
	}
	else
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
	
	self.ownerSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsContractsOwner];

	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	[self reloadContracts];
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
	self.contractsTableView = nil;
	self.ownerSegmentControl = nil;
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	self.contracts = nil;
	self.charContracts = nil;
	self.corpContracts = nil;
	self.filteredValues = nil;
	self.conquerableStations = nil;
	self.charFilter = nil;
	self.corpFilter = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction) onChangeOwner:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:self.ownerSegmentControl.selectedSegmentIndex forKey:SettingsContractsOwner];
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
		return self.filteredValues.count;
	else {
		return self.contracts.count;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"ContractCellView";
	
    ContractCellView *cell = (ContractCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSString *nibName;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			nibName = tableView == self.contractsTableView ? @"ContractCellView" : @"ContractCellViewCompact";
		else
			nibName = @"ContractCellView";
		
        cell = [ContractCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *contractDic;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		contractDic = [self.filteredValues objectAtIndex:indexPath.row];
	else {
		contractDic = [self.contracts objectAtIndex:indexPath.row];
	}
	EVEContractsItem *contract = [contractDic valueForKey:@"contract"];
	
	cell.statusLabel.text = [contractDic valueForKey:@"remains"];
	cell.statusLabel.textColor = [contractDic valueForKey:@"remainsColor"];
	cell.typeLabel.text = [contractDic valueForKey:@"typeString"];
	cell.titleLabel.text = contract.title.length > 0 ? contract.title : @"No title";
	cell.locationLabel.text = [contractDic valueForKey:@"location"];
	cell.characterLabel.text = [contractDic valueForKey:@"issuerName"];
	cell.startTimeLabel.text = [contractDic valueForKey:@"dateIssued"];
	cell.priceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:contract.reward > 0 ? contract.reward : contract.price] numberStyle:NSNumberFormatterDecimalStyle]];
	cell.priceTitleLabel.text = contract.reward > 0 ? NSLocalizedString(@"Reward:", nil) : NSLocalizedString(@"Price:", nil);
	cell.buyoutLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:contract.buyout] numberStyle:NSNumberFormatterDecimalStyle]];
	
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
		return tableView == self.contractsTableView ? 71 : 123;
	else
		return 123;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	ContractViewController *controller = [[ContractViewController alloc] initWithNibName:@"ContractViewController" bundle:nil];
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
		controller.contract = [[self.filteredValues objectAtIndex:indexPath.row] valueForKeyPath:@"contract"];
	else
		controller.contract = [[self.contracts objectAtIndex:indexPath.row] valueForKeyPath:@"contract"];
	controller.corporate = self.ownerSegmentControl.selectedSegmentIndex == 1;

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[controller.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)]];
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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background4.png"]];
	else {
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]];
		tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
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
	[self reloadContracts];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private

- (void) reloadContracts {
	
	BOOL corporate = (self.ownerSegmentControl.selectedSegmentIndex == 1);
	NSMutableArray *currentContracts = corporate ? self.corpContracts : self.charContracts;
	EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"contractsFilter" ofType:@"plist"]]];
	
	self.contracts = nil;
	if (!currentContracts) {
		if (corporate) {
			self.corpContracts = [[NSMutableArray alloc] init];
			currentContracts = self.corpContracts;
		}
		else {
			self.charContracts = [[NSMutableArray alloc] init];
			currentContracts = self.charContracts;
		}
		EVEAccount *account = [EVEAccount currentAccount];
		__block EUOperation *operation = [EUOperation operationWithIdentifier:[NSString stringWithFormat:@"ContractsViewController+Load%d", corporate] name:NSLocalizedString(@"Loading Contracts", nil)];
		__weak EUOperation* weakOperation = operation;
		NSMutableArray *contractsTmp = [NSMutableArray array];
		
		[operation addExecutionBlock:^(void) {
			NSError *error = nil;
			
			if (!account) {
				return;
			}
			
			EVEContracts *eveContracts;
			if (corporate)
				eveContracts = [EVEContracts contractsWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID corporate:corporate error:&error progressHandler:nil];
			else
				eveContracts = [EVEContracts contractsWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID corporate:corporate error:&error progressHandler:nil];
			weakOperation.progress = 0.5;
			if (error) {
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			}
			else {
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
				[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
				//NSMutableDictionary *characters = [NSMutableDictionary dictionary];
				NSMutableSet* charIDs = [NSMutableSet set];
				
				NSDate *currentTime = [eveContracts serverTimeWithLocalTime:[NSDate date]];
				float n = eveContracts.contractList.count;
				float i = 0;
				for (EVEContractsItem *contract in eveContracts.contractList) {
					weakOperation.progress = 0.5 + i++ / n / 2;
					NSString *remains;
					UIColor *remainsColor;
					NSString *stationName = nil;
					
					EVEDBStaStation *station = [EVEDBStaStation staStationWithStationID:contract.startStationID error:nil];
					
					if (!station) {
						EVEConquerableStationListItem *conquerableStation = self.conquerableStations[@(contract.startStationID)];
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
					
					NSString *statusString = [contract localizedStatusString];
					if (contract.status <= EVEContractStatusCompletedByContractor) {
						remains = [NSString stringWithFormat:NSLocalizedString(@"Completed: %@", nil), [dateFormatter stringFromDate:contract.dateCompleted]];
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
				
				[contractsTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"dateIssued" ascending:NO]]];
				
				if (charIDs.count > 0) {
					NSError *error = nil;
					EVECharacterName *characterNames = [EVECharacterName characterNameWithIDs:[charIDs allObjects] error:&error progressHandler:nil];
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
		}];
		
		[operation setCompletionBlockInCurrentThread:^(void) {
			if (![weakOperation isCancelled]) {
				if (corporate) {
					self.corpFilter = filterTmp;
				}
				else {
					self.charFilter = filterTmp;
				}
				[currentContracts addObjectsFromArray:contractsTmp];
				if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate)
					[self reloadContracts];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		EUFilter *filter = corporate ? self.corpFilter : self.charFilter;
		NSMutableArray *contractsTmp = [NSMutableArray array];
		if (filter) {
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ContractsViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				[contractsTmp addObjectsFromArray:[filter applyToValues:currentContracts]];
			}];
			
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![weakOperation isCancelled]) {
					if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						self.contracts = contractsTmp;
						[self searchWithSearchString:self.searchBar.text];
						[self.contractsTableView reloadData];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else
			self.contracts = currentContracts;
	}
	[self.contractsTableView reloadData];
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
	if (!account) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contracts = nil;
			self.charContracts = nil;
			self.corpContracts = nil;
			self.filteredValues = nil;
			self.conquerableStations = nil;
			self.charFilter = nil;
			self.corpFilter = nil;
			[self reloadContracts];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		self.contracts = nil;
		self.charContracts = nil;
		self.corpContracts = nil;
		self.filteredValues = nil;
		self.conquerableStations = nil;
		self.charFilter = nil;
		self.corpFilter = nil;
		[self reloadContracts];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (self.contracts.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"ContractsViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		for (NSDictionary *contract in self.contracts) {
			if ([weakOperation isCancelled])
				break;
			if (([contract valueForKeyPath:@"remains"] && [[contract valueForKeyPath:@"remains"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([contract valueForKeyPath:@"location"] && [[contract valueForKeyPath:@"location"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([contract valueForKeyPath:@"issuerName"] && [[contract valueForKeyPath:@"issuerName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([contract valueForKeyPath:@"dateIssued"] && [[contract valueForKeyPath:@"dateIssued"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([contract valueForKeyPath:@"contract.title"] && [[contract valueForKeyPath:@"contract.title"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([contract valueForKeyPath:@"typeString"] && [[contract valueForKeyPath:@"typeString"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
				[filteredValuesTmp addObject:contract];
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.filteredValues = filteredValuesTmp;
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (IBAction) onClose:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

@end