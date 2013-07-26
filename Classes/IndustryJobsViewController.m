//
//  IndustryJobsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IndustryJobsViewController.h"
#import "EVEOnlineAPI.h"
#import "EVEDBAPI.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "SelectCharacterBarButtonItem.h"
#import "UIAlertView+Error.h"
#import "IndustryJobCellView.h"
#import "ItemViewController.h"
#import "NSString+TimeLeft.h"

@interface IndustryJobsViewController()
@property(nonatomic, strong) NSMutableArray *filteredValues;
@property(nonatomic, strong) NSMutableArray *jobs;
@property(nonatomic, strong) NSMutableArray *charJobs;
@property(nonatomic, strong) NSMutableArray *corpJobs;
@property(nonatomic, strong) NSMutableDictionary *conquerableStations;
@property(nonatomic, strong) EUFilter *charFilter;
@property(nonatomic, strong) EUFilter *corpFilter;

- (void) reloadJobs;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
@end

@implementation IndustryJobsViewController

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

	self.ownerSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsIndustryJobsOwner];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:EVEAccountDidSelectNotification object:nil];
	[self reloadJobs];
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
	self.jobs = nil;
	self.charJobs = nil;
	self.corpJobs = nil;
	self.filteredValues = nil;
	self.conquerableStations = nil;
	self.charFilter = nil;
	self.corpFilter = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction) onChangeOwner:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:self.ownerSegmentControl.selectedSegmentIndex forKey:SettingsIndustryJobsOwner];
	[self reloadJobs];
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
		return self.jobs.count;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"IndustryJobCellView";
	
    IndustryJobCellView *cell = (IndustryJobCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSString *nibName;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			nibName = tableView == self.tableView ? @"IndustryJobCellView" : @"IndustryJobCellViewCompact";
		else
			nibName = @"IndustryJobCellView";

        cell = [IndustryJobCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *job;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		job = [self.filteredValues objectAtIndex:indexPath.row];
	else {
		job = [self.jobs objectAtIndex:indexPath.row];
	}
	
	cell.remainsLabel.text = [job valueForKey:@"remains"];
	cell.typeNameLabel.text = [job valueForKey:@"typeName"];
	cell.locationLabel.text = [job valueForKey:@"location"];
	cell.startTimeLabel.text = [job valueForKey:@"startTime"];
	cell.characterLabel.text = [job valueForKey:@"characterName"];
	cell.iconImageView.image = [UIImage imageNamed:[job valueForKey:@"imageName"]];
	cell.activityLabel.text = [job valueForKey:@"activityName"];
	cell.activityImageView.image = [UIImage imageNamed:[job valueForKey:@"activityImageName"]];
	cell.remainsLabel.textColor = [job valueForKey:@"remainsColor"];
	
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
		return tableView == self.tableView ? 53 : 72;
	else
		return 72;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
		controller.type = [[self.filteredValues objectAtIndex:indexPath.row] valueForKey:@"type"];
	else
		controller.type = [[self.jobs objectAtIndex:indexPath.row] valueForKey:@"type"];
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
	[self reloadJobs];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private

- (void) reloadJobs {
	
	BOOL corporate = (self.ownerSegmentControl.selectedSegmentIndex == 1);
	NSMutableArray *currentJobs = corporate ? self.corpJobs : self.charJobs;
	EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"industryJobsFilter" ofType:@"plist"]]];
	
	self.jobs = nil;
	if (!currentJobs) {
		if (corporate) {
			self.corpJobs = [[NSMutableArray alloc] init];
			currentJobs = self.corpJobs;
		}
		else {
			self.charJobs = [[NSMutableArray alloc] init];
			currentJobs = self.charJobs;
		}
		
		EVEAccount *account = [EVEAccount currentAccount];
		__block EUOperation *operation = [EUOperation operationWithIdentifier:[NSString stringWithFormat:@"IndustryJobsViewController+Load%d", corporate] name:NSLocalizedString(@"Loading Industry Jobs", nil)];
		__weak EUOperation* weakOperation = operation;
		NSMutableArray *jobsTmp = [NSMutableArray array];
		
		[operation addExecutionBlock:^(void) {
			NSError *error = nil;
			
			if (!account)
				return;
			
			EVEIndustryJobs *industryJobs;
			if (corporate)
				industryJobs = [EVEIndustryJobs industryJobsWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID corporate:corporate error:&error progressHandler:nil];
			else
				industryJobs = [EVEIndustryJobs industryJobsWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID corporate:corporate error:&error progressHandler:nil];

			if (error) {
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			}
			else {
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
				[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
				NSMutableSet *charIDs = [NSMutableSet set];
				
				NSDate *currentTime = [industryJobs serverTimeWithLocalTime:[NSDate date]];
				
				float n = industryJobs.jobs.count;
				float i = 0;
				for (EVEIndustryJobsItem *job in industryJobs.jobs) {
					weakOperation.progress = i++ / n / 2;
					NSString *remains;
					EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:job.outputTypeID error:nil];
					NSString *location = nil;
					NSString *charID = [NSString stringWithFormat:@"%lld", job.installerID];
					UIColor *remainsColor;
					
					if (job.installedItemLocationID == INT_MAX) {
						EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:job.installedInSolarSystemID error:nil];
						location = solarSystem.solarSystemName;
					}
					else if (66000000 < job.installedItemLocationID && job.installedItemLocationID < 66014933) { //staStations
						int locationID = job.installedItemLocationID - 6000001;
						EVEDBStaStation *station = [EVEDBStaStation staStationWithStationID:locationID error:nil];
						if (station)
							location = [NSString stringWithFormat:@"%@ / %@", station.stationName, station.solarSystem.solarSystemName];
						else
							location = NSLocalizedString(@"Unknown Location", nil);
					}
					else if (66014934 < job.installedItemLocationID && job.installedItemLocationID < 67999999) { //staStations
						int locationID = job.installedItemLocationID - 6000000;
						EVEConquerableStationListItem *conquerableStation = self.conquerableStations[@(locationID)];
						if (conquerableStation) {
							EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID error:nil];
							if (solarSystem)
								location = [NSString stringWithFormat:@"%@ / %@", conquerableStation.stationName, solarSystem.solarSystemName];
							else
								location = conquerableStation.stationName;
						}
						else
							location = NSLocalizedString(@"Unknown Location", nil);
					}
					else if (60014861 < job.installedItemLocationID && job.installedItemLocationID < 60014928) { //ConqStations
						EVEConquerableStationListItem *conquerableStation = self.conquerableStations[@(job.installedItemLocationID)];
						if (conquerableStation) {
							EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID error:nil];
							if (solarSystem)
								location = [NSString stringWithFormat:@"%@ / %@", conquerableStation.stationName, solarSystem.solarSystemName];
							else
								location = conquerableStation.stationName;
						}
						else
							location = NSLocalizedString(@"Unknown Location", nil);
					}
					else if (60000000 < job.installedItemLocationID && job.installedItemLocationID < 61000000) { //staStations
						EVEDBStaStation *station = [EVEDBStaStation staStationWithStationID:job.installedItemLocationID error:nil];
						if (station)
							location = [NSString stringWithFormat:@"%@ / %@", station.stationName, station.solarSystem.solarSystemName];
						else
							location = NSLocalizedString(@"Unknown Location", nil);
					}
					else if (61000000 <= job.installedItemLocationID) { //ConqStations
						EVEConquerableStationListItem *conquerableStation = self.conquerableStations[@(job.installedItemLocationID)];
						if (conquerableStation) {
							EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID error:nil];
							if (solarSystem)
								location = [NSString stringWithFormat:@"%@ / %@", conquerableStation.stationName, solarSystem.solarSystemName];
							else
								location = conquerableStation.stationName;
						}
						else
							location = NSLocalizedString(@"Unknown Location", nil);
					}
					else { //mapDenormalize
						EVEDBMapDenormalize *denormalize = [EVEDBMapDenormalize mapDenormalizeWithItemID:job.installedItemLocationID error:nil];
						if (denormalize) {
							if (denormalize.solarSystem)
								location = [NSString stringWithFormat:@"%@ / %@", denormalize.itemName, denormalize.solarSystem.solarSystemName];
							else
								location = denormalize.itemName;
						}
						else
							location = NSLocalizedString(@"Unknown Location", nil);
					}
					
					NSString *status;
					if (!job.completed) {
						NSTimeInterval remainsTime = [job.endProductionTime timeIntervalSinceDate:currentTime];
						if (remainsTime > 0) {
							NSTimeInterval productionTime = [job.endProductionTime timeIntervalSinceDate:job.beginProductionTime];
							NSTimeInterval progressTime = [currentTime timeIntervalSinceDate:job.beginProductionTime];
							remains = [NSString stringWithFormat:NSLocalizedString(@"Remaining: %@ (%d%%)", nil), [NSString stringWithTimeLeft:remainsTime], (int) (progressTime * 100 / productionTime)];
							remainsColor = [UIColor yellowColor];
							status = NSLocalizedString(@"In Progress", nil);
						}
						else {
							remains = [NSString stringWithFormat:NSLocalizedString(@"Completed: %@", nil), [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor greenColor];
							status = NSLocalizedString(@"Completed", nil);
						}
					}
					else {
						if (job.completedStatus == 0) {
							remains = [NSString stringWithFormat:NSLocalizedString(@"Failed: %@", nil), [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor redColor];
							status = NSLocalizedString(@"Failed", nil);
						}
						else if (job.completedStatus == 1) {
							remains = [NSString stringWithFormat:NSLocalizedString(@"Delivered: %@", nil), [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor greenColor];
							status = NSLocalizedString(@"Delivered", nil);
						}
						else if (job.completedStatus == 2) {
							remains = [NSString stringWithFormat:NSLocalizedString(@"Aborted: %@", nil), [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor redColor];
							status = NSLocalizedString(@"Aborted", nil);
						}
						else if (job.completedStatus == 3) {
							remains = [NSString stringWithFormat:NSLocalizedString(@"GM aborted: %@", nil), [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor redColor];
							status = NSLocalizedString(@"GM aborted", nil);
						}
						else if (job.completedStatus == 4) {
							remains = [NSString stringWithFormat:NSLocalizedString(@"Inflight unanchored: %@", nil), [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor redColor];
							status = NSLocalizedString(@"Inflight unanchored", nil);
						}
						else if (job.completedStatus == 5) {
							remains = [NSString stringWithFormat:NSLocalizedString(@"Destroyed: %@", nil), [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor redColor];
							status = NSLocalizedString(@"Destroyed", nil);
						}
						else {
							remains = NSLocalizedString(@"Unknown Location", nil);
							remainsColor = [UIColor redColor];
							status = NSLocalizedString(@"Unknown Status", nil);
						}
					}
					[charIDs addObject:charID];
					
					EVEDBRamActivity *activity = [EVEDBRamActivity ramActivityWithActivityID:job.activityID error:nil];
					
					[jobsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										remains, @"remains",
										remainsColor, @"remainsColor",
										[NSString stringWithFormat:NSLocalizedString(@"%@ (%d runs)", nil), type.typeName, job.runs], @"typeName",
										[type typeSmallImageName], @"imageName",
										location, @"location",
										charID, @"charID",
										@"", @"characterName",
										activity.activityName, @"activityName",
										activity.iconImageName, @"activityImageName",
										[dateFormatter stringFromDate:job.installTime], @"startTime",
										type, @"type",
										status, @"status",
										nil]];
				}
				
				[jobsTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:NO]]];
				weakOperation.progress = 0.75;
				if (charIDs.count > 0) {
					NSError *error = nil;
					EVECharacterName *characterNames = [EVECharacterName characterNameWithIDs:[charIDs allObjects] error:&error progressHandler:nil];
					if (!error) {
						for (NSMutableDictionary *job in jobsTmp) {
							NSString *charID = [job valueForKey:@"charID"];
							NSString *charName = [characterNames.characters valueForKey:charID];
							if (!charName)
								charName = @"";
							[job setValue:charName forKey:@"characterName"];
						}
					}
				}
				weakOperation.progress = 1.0;
				[filterTmp updateWithValues:jobsTmp];
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
				[currentJobs addObjectsFromArray:jobsTmp];
				if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate)
					[self reloadJobs];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		EUFilter *filter = corporate ? self.corpFilter : self.charFilter;
		NSMutableArray *jobsTmp = [NSMutableArray array];
		if (filter) {
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"IndustryJobsViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				[jobsTmp addObjectsFromArray:[filter applyToValues:currentJobs]];
			}];
			
			[operation setCompletionBlockInMainThread:^(void) {
				if (![weakOperation isCancelled]) {
					if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						self.jobs = jobsTmp;
						[self searchWithSearchString:self.searchBar.text];
						[self.tableView reloadData];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else
			self.jobs = currentJobs;
	}
	[self.tableView reloadData];
}

- (NSDictionary*) conquerableStations {
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
			self.jobs = nil;
			self.charJobs = nil;
			self.corpJobs = nil;
			self.filteredValues = nil;
			self.conquerableStations = nil;
			self.charFilter = nil;
			self.corpFilter = nil;
			[self reloadJobs];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		self.jobs = nil;
		self.charJobs = nil;
		self.corpJobs = nil;
		self.filteredValues = nil;
		self.conquerableStations = nil;
		self.charFilter = nil;
		self.corpFilter = nil;
		[self reloadJobs];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (self.jobs.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"IndustryJobsViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		for (NSDictionary *job in self.jobs) {
			if ([weakOperation isCancelled])
				break;
			if (([job valueForKey:@"remains"] && [[job valueForKey:@"remains"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([job valueForKey:@"typeName"] && [[job valueForKey:@"typeName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([job valueForKey:@"location"] && [[job valueForKey:@"location"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([job valueForKey:@"characterName"] && [[job valueForKey:@"characterName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([job valueForKey:@"activityName"] && [[job valueForKey:@"activityName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([job valueForKey:@"startTime"] && [[job valueForKey:@"startTime"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
				[filteredValuesTmp addObject:job];
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