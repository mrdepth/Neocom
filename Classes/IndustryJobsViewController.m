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
#import "NibTableViewCell.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "SelectCharacterBarButtonItem.h"
#import "UIAlertView+Error.h"
#import "IndustryJobCellView.h"
#import "ItemViewController.h"
#import "NSString+TimeLeft.h"

@interface IndustryJobsViewController(Private)
- (void) reloadJobs;
- (NSDictionary*) conquerableStations;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
@end

@implementation IndustryJobsViewController
@synthesize jobsTableView;
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
	self.title = @"Industry Jobs";
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:searchBar] autorelease]];
		[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:ownerSegmentControl] autorelease]];
		self.filterPopoverController = [[[UIPopoverController alloc] initWithContentViewController:filterNavigationViewController] autorelease];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
	}
	else
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];

	ownerSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsIndustryJobsOwner];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	[self reloadJobs];
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
	self.jobsTableView = nil;
	self.ownerSegmentControl = nil;
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	[jobs release];
	[charJobs release];
	[corpJobs release];
	[filteredValues release];
	[conquerableStations release];
	[charFilter release];
	[corpFilter release];
	jobs = charJobs = corpJobs = filteredValues = nil;
	conquerableStations = nil;
	charFilter = corpFilter = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[jobsTableView release];
	[ownerSegmentControl release];
	[searchBar release];
	[filteredValues release];
	[jobs release];
	[charJobs release];
	[corpJobs release];
	[conquerableStations release];
	[filterViewController release];
	[filterNavigationViewController release];
	[filterPopoverController release];
	[charFilter release];
	[corpFilter release];
    [super dealloc];
}

- (IBAction) onChangeOwner:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:ownerSegmentControl.selectedSegmentIndex forKey:SettingsIndustryJobsOwner];
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
		return filteredValues.count;
	else {
		return jobs.count;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"IndustryJobCellView";
	
    IndustryJobCellView *cell = (IndustryJobCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSString *nibName;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			nibName = tableView == jobsTableView ? @"IndustryJobCellView-iPad" : @"IndustryJobCellView";
		else
			nibName = @"IndustryJobCellView";

        cell = [IndustryJobCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *job;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		job = [filteredValues objectAtIndex:indexPath.row];
	else {
		job = [jobs objectAtIndex:indexPath.row];
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
		return tableView == jobsTableView ? 53 : 72;
	else
		return 72;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemViewController-iPad" : @"ItemViewController")
																		  bundle:nil];
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
		controller.type = [[filteredValues objectAtIndex:indexPath.row] valueForKey:@"type"];
	else
		controller.type = [[jobs objectAtIndex:indexPath.row] valueForKey:@"type"];
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
	[self reloadJobs];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

@end

@implementation IndustryJobsViewController(Private)

- (void) reloadJobs {
	
	BOOL corporate = (ownerSegmentControl.selectedSegmentIndex == 1);
	NSMutableArray *currentJobs = corporate ? corpJobs : charJobs;
	EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"industryJobsFilter" ofType:@"plist"]]];
	
	[jobs release];
	jobs = nil;
	if (!currentJobs) {
		if (corporate) {
			corpJobs = [[NSMutableArray alloc] init];
			currentJobs = corpJobs;
		}
		else {
			charJobs = [[NSMutableArray alloc] init];
			currentJobs = charJobs;
		}
		
		EVEAccount *account = [EVEAccount currentAccount];
		__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:[NSString stringWithFormat:@"IndustryJobsViewController+Load%d", corporate]];
		NSMutableArray *jobsTmp = [NSMutableArray array];
		
		[operation addExecutionBlock:^(void) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSError *error = nil;
			
			if (!account) {
				[pool release];
				return;
			}
			
			//EVEIndustryJobs *industryJobs = [EVEIndustryJobs industryJobsWithUserID:character.userID apiKey:character.apiKey characterID:character.characterID corporate:corporate error:&error];
			EVEIndustryJobs *industryJobs;
			if (corporate)
				industryJobs = [EVEIndustryJobs industryJobsWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID corporate:corporate error:&error];
			else
				industryJobs = [EVEIndustryJobs industryJobsWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID corporate:corporate error:&error];

			if (error) {
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			}
			else {
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
				NSMutableSet *charIDs = [NSMutableSet set];
				
				NSDate *currentTime = [industryJobs serverTimeWithLocalTime:[NSDate date]];
				
				for (EVEIndustryJobsItem *job in industryJobs.jobs) {
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
							location = @"Unknown";
					}
					else if (66014934 < job.installedItemLocationID && job.installedItemLocationID < 67999999) { //staStations
						int locationID = job.installedItemLocationID - 6000000;
						EVEConquerableStationListItem *conquerableStation = [[self conquerableStations] valueForKey:[NSString stringWithFormat:@"%d", locationID]];
						if (conquerableStation) {
							EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID error:nil];
							if (solarSystem)
								location = [NSString stringWithFormat:@"%@ / %@", conquerableStation.stationName, solarSystem.solarSystemName];
							else
								location = conquerableStation.stationName;
						}
						else
							location = @"Unknown";
					}
					else if (60014861 < job.installedItemLocationID && job.installedItemLocationID < 60014928) { //ConqStations
						EVEConquerableStationListItem *conquerableStation = [[self conquerableStations] valueForKey:[NSString stringWithFormat:@"%lld", job.installedItemLocationID]];
						if (conquerableStation) {
							EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID error:nil];
							if (solarSystem)
								location = [NSString stringWithFormat:@"%@ / %@", conquerableStation.stationName, solarSystem.solarSystemName];
							else
								location = conquerableStation.stationName;
						}
						else
							location = @"Unknown";
					}
					else if (60000000 < job.installedItemLocationID && job.installedItemLocationID < 61000000) { //staStations
						EVEDBStaStation *station = [EVEDBStaStation staStationWithStationID:job.installedItemLocationID error:nil];
						if (station)
							location = [NSString stringWithFormat:@"%@ / %@", station.stationName, station.solarSystem.solarSystemName];
						else
							location = @"Unknown";
					}
					else if (61000000 <= job.installedItemLocationID) { //ConqStations
						EVEConquerableStationListItem *conquerableStation = [[conquerableStations self] valueForKey:[NSString stringWithFormat:@"%lld", job.installedItemLocationID]];
						if (conquerableStation) {
							EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:conquerableStation.solarSystemID error:nil];
							if (solarSystem)
								location = [NSString stringWithFormat:@"%@ / %@", conquerableStation.stationName, solarSystem.solarSystemName];
							else
								location = conquerableStation.stationName;
						}
						else
							location = @"Unknown";
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
							location = @"Unknown";
					}
					
					NSString *status;
					if (!job.completed) {
						NSTimeInterval remainsTime = [job.endProductionTime timeIntervalSinceDate:currentTime];
						if (remainsTime > 0) {
							NSTimeInterval productionTime = [job.endProductionTime timeIntervalSinceDate:job.beginProductionTime];
							NSTimeInterval progressTime = [currentTime timeIntervalSinceDate:job.beginProductionTime];
							remains = [NSString stringWithFormat:@"Remaining: %@ (%d%%)", [NSString stringWithTimeLeft:remainsTime], (int) (progressTime * 100 / productionTime)];
							remainsColor = [UIColor yellowColor];
							status = @"In Progress";
						}
						else {
							remains = [NSString stringWithFormat:@"Completed: %@", [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor greenColor];
							status = @"Completed";
						}
					}
					else {
						if (job.completedStatus == 0) {
							remains = [NSString stringWithFormat:@"Failed: %@", [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor redColor];
							status = @"Failed";
						}
						else if (job.completedStatus == 1) {
							remains = [NSString stringWithFormat:@"Delivered: %@", [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor greenColor];
							status = @"Delivered";
						}
						else if (job.completedStatus == 2) {
							remains = [NSString stringWithFormat:@"Aborted: %@", [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor redColor];
							status = @"Aborted";
						}
						else if (job.completedStatus == 3) {
							remains = [NSString stringWithFormat:@"GM aborted: %@", [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor redColor];
							status = @"GM aborted";
						}
						else if (job.completedStatus == 4) {
							remains = [NSString stringWithFormat:@"Inflight unanchored: %@", [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor redColor];
							status = @"Inflight unanchored";
						}
						else if (job.completedStatus == 5) {
							remains = [NSString stringWithFormat:@"Destroyed: %@", [dateFormatter stringFromDate:job.endProductionTime]];
							remainsColor = [UIColor redColor];
							status = @"Destroyed";
						}
						else {
							remains = @"Unknown";
							remainsColor = [UIColor redColor];
							status = @"Unknown";
						}
					}
					[charIDs addObject:charID];
					
					EVEDBRamActivity *activity = [EVEDBRamActivity ramActivityWithActivityID:job.activityID error:nil];
					
					[jobsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										remains, @"remains",
										remainsColor, @"remainsColor",
										[NSString stringWithFormat:@"%@ (%d runs)", type.typeName, job.runs], @"typeName",
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
				[dateFormatter release];
				
				[jobsTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:NO]]];
				
				if (charIDs.count > 0) {
					NSError *error = nil;
					EVECharacterName *characterNames = [EVECharacterName characterNameWithIDs:[charIDs allObjects] error:&error];
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
				[filterTmp updateWithValues:jobsTmp];
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
				[currentJobs addObjectsFromArray:jobsTmp];
				if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate)
					[self reloadJobs];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		EUFilter *filter = corporate ? corpFilter : charFilter;
		NSMutableArray *jobsTmp = [NSMutableArray array];
		if (filter) {
			__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"IndustryJobsViewController+Filter"];
			[operation addExecutionBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				[jobsTmp addObjectsFromArray:[filter applyToValues:currentJobs]];
				[pool release];
			}];
			
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![operation isCancelled]) {
					if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						[jobs release];
						jobs = [jobsTmp retain];
						[self searchWithSearchString:self.searchBar.text];
						[jobsTableView reloadData];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else
			jobs = [currentJobs retain];
	}
	[jobsTableView reloadData];
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
			[jobs release];
			[charJobs release];
			[corpJobs release];
			jobs = charJobs = corpJobs = nil;
			[filteredValues release];
			filteredValues = nil;
			[charFilter release];
			[corpFilter release];
			charFilter = corpFilter = nil;
			[self reloadJobs];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		[jobs release];
		[charJobs release];
		[corpJobs release];
		jobs = charJobs = corpJobs = nil;
		[filteredValues release];
		filteredValues = nil;
		[charFilter release];
		[corpFilter release];
		charFilter = corpFilter = nil;
		[self reloadJobs];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (jobs.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"IndustryJobsViewController+Search"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		for (NSDictionary *job in jobs) {
			if (([job valueForKey:@"remains"] && [[job valueForKey:@"remains"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([job valueForKey:@"typeName"] && [[job valueForKey:@"typeName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([job valueForKey:@"location"] && [[job valueForKey:@"location"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([job valueForKey:@"characterName"] && [[job valueForKey:@"characterName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([job valueForKey:@"activityName"] && [[job valueForKey:@"activityName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([job valueForKey:@"startTime"] && [[job valueForKey:@"startTime"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
				[filteredValuesTmp addObject:job];
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