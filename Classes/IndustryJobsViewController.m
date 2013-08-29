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
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "appearance.h"
#import "NSDate+DaysAgo.h"
#import "UIViewController+Neocom.h"

@interface IndustryJobsViewController()
@property(nonatomic, strong) NSMutableArray *filteredValues;
@property(nonatomic, strong) NSMutableArray *activeJobs;
@property(nonatomic, strong) NSMutableArray *finishedJobs;
@property(nonatomic, strong) NSMutableArray *charActiveJobs;
@property(nonatomic, strong) NSMutableArray *charFinishedJobs;
@property(nonatomic, strong) NSMutableArray *corpActiveJobs;
@property(nonatomic, strong) NSMutableArray *corpFinishedJobs;

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
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	
	self.navigationItem.titleView = self.ownerSegmentControl;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.searchBar]];
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
    return self.searchDisplayController.searchResultsTableView == tableView ? 1 : 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return self.filteredValues.count;
	else
		return section == 0 ? self.activeJobs.count : self.finishedJobs.count;
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
		job = self.filteredValues[indexPath.row];
	else {
		job = indexPath.section == 0 ? self.activeJobs[indexPath.row] : self.finishedJobs[indexPath.row];
	}
	
	cell.remainsLabel.text = job[@"remains"];
	cell.typeNameLabel.text = job[@"typeName"];
	cell.locationLabel.text = job[@"location"];
	cell.startTimeLabel.text = job[@"startTime"];
	cell.characterLabel.text = job[@"characterName"];
	cell.iconImageView.image = [UIImage imageNamed:job[@"imageName"]];
	cell.activityLabel.text = job[@"activityName"];
	cell.activityImageView.image = [UIImage imageNamed:job[@"activityImageName"]];
	cell.remainsLabel.backgroundColor = job[@"remainsColor"];
	cell.remainsLabel.progress = [job[@"progress"] floatValue];
	
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
		return section == 0 ? [NSString stringWithFormat:NSLocalizedString(@"Active Jobs (%d)", nil), self.activeJobs.count] : NSLocalizedString(@"Finished Jobs", nil);
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
		return tableView == self.tableView ? 58 : 78;
	else
		return 78;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
		controller.type = self.filteredValues[indexPath.row][@"type"];
	else
		controller.type = indexPath.section == 0 ? self.activeJobs[indexPath.row][@"type"] : self.finishedJobs[indexPath.row][@"type"];
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
	[self reloadJobs];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void) reloadJobs {
	
	BOOL corporate = (self.ownerSegmentControl.selectedSegmentIndex == 1);
	NSMutableArray *currentActiveJobs = corporate ? self.corpActiveJobs : self.charActiveJobs;
	NSMutableArray *currentFinishedJobs = corporate ? self.corpFinishedJobs : self.charFinishedJobs;
	EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"industryJobsFilter" ofType:@"plist"]]];
	
	self.activeJobs = nil;
	self.finishedJobs = nil;
	if (!currentActiveJobs || !currentFinishedJobs) {
		if (corporate) {
			self.corpActiveJobs = [[NSMutableArray alloc] init];
			self.corpFinishedJobs = [[NSMutableArray alloc] init];
			currentActiveJobs = self.corpActiveJobs;
			currentFinishedJobs = self.corpFinishedJobs;
		}
		else {
			self.charActiveJobs = [[NSMutableArray alloc] init];
			self.charFinishedJobs = [[NSMutableArray alloc] init];
			currentActiveJobs = self.charActiveJobs;
			currentFinishedJobs = self.charFinishedJobs;
		}
		
		EVEAccount *account = [EVEAccount currentAccount];
		EUOperation *operation = [EUOperation operationWithIdentifier:[NSString stringWithFormat:@"IndustryJobsViewController+Load%d", corporate] name:NSLocalizedString(@"Loading Industry Jobs", nil)];
		__weak EUOperation* weakOperation = operation;
		NSMutableArray *activeJobsTmp = [NSMutableArray array];
		NSMutableArray *finishedJobsTmp = [NSMutableArray array];
		
		[operation addExecutionBlock:^(void) {
			NSError *error = nil;
			
			if (!account)
				return;
			
			EVEIndustryJobs *industryJobs;
			if (corporate)
				industryJobs = [EVEIndustryJobs industryJobsWithKeyID:account.corpAPIKey.keyID vCode:account.corpAPIKey.vCode characterID:account.character.characterID corporate:corporate error:&error progressHandler:nil];
			else
				industryJobs = [EVEIndustryJobs industryJobsWithKeyID:account.charAPIKey.keyID vCode:account.charAPIKey.vCode characterID:account.character.characterID corporate:corporate error:&error progressHandler:nil];

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
						else if (job.installedInSolarSystemID > 0) {
							EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:job.installedInSolarSystemID error:nil];
							location = solarSystem.solarSystemName;
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
					BOOL finished = YES;
					CGFloat progress = 0.0f;
					if (!job.completed) {
						NSTimeInterval remainsTime = [job.endProductionTime timeIntervalSinceDate:currentTime];
						if (remainsTime > 0) {
							NSTimeInterval productionTime = [job.endProductionTime timeIntervalSinceDate:job.beginProductionTime];
							NSTimeInterval progressTime = [currentTime timeIntervalSinceDate:job.beginProductionTime];
							progress = (progressTime / productionTime);
							remains = [NSString stringWithFormat:@"%@ (%d%%)", [NSString stringWithTimeLeft:remainsTime], (int) (progress * 100)];
							remainsColor = [UIColor colorWithNumber:AppearanceGreenProgressColor];
							status = NSLocalizedString(@"In Progress", nil);
							finished = NO;
						}
						else {
							progress = 1.0f;
							remains = [NSString stringWithFormat:NSLocalizedString(@"Completed: %@", nil), [job.endProductionTime daysAgoStringWithTime:YES]];
							remainsColor = [UIColor colorWithNumber:AppearanceGreenProgressColor];
							status = NSLocalizedString(@"Completed", nil);
						}
					}
					else {
						if (job.completedStatus == 0) {
							progress = 1.0f;
							remains = [NSString stringWithFormat:NSLocalizedString(@"Failed: %@", nil), [job.endProductionTime daysAgoStringWithTime:YES]];
							remainsColor = [UIColor colorWithNumber:AppearanceRedProgressColor];
							status = NSLocalizedString(@"Failed", nil);
						}
						else if (job.completedStatus == 1) {
							remains = [NSString stringWithFormat:NSLocalizedString(@"Delivered: %@", nil), [job.endProductionTime daysAgoStringWithTime:YES]];
							progress = 1.0f;
							remainsColor = [UIColor colorWithNumber:AppearanceGreenProgressColor];
							status = NSLocalizedString(@"Delivered", nil);
						}
						else if (job.completedStatus == 2) {
							remains = [NSString stringWithFormat:NSLocalizedString(@"Aborted: %@", nil), [job.endProductionTime daysAgoStringWithTime:YES]];
							remainsColor = [UIColor colorWithNumber:AppearanceRedProgressColor];
							status = NSLocalizedString(@"Aborted", nil);
						}
						else if (job.completedStatus == 3) {
							remains = [NSString stringWithFormat:NSLocalizedString(@"GM aborted: %@", nil), [job.endProductionTime daysAgoStringWithTime:YES]];
							remainsColor = [UIColor colorWithNumber:AppearanceRedProgressColor];
							status = NSLocalizedString(@"GM aborted", nil);
						}
						else if (job.completedStatus == 4) {
							remains = [NSString stringWithFormat:NSLocalizedString(@"Inflight unanchored: %@", nil), [job.endProductionTime daysAgoStringWithTime:YES]];
							remainsColor = [UIColor colorWithNumber:AppearanceRedProgressColor];
							status = NSLocalizedString(@"Inflight unanchored", nil);
						}
						else if (job.completedStatus == 5) {
							remains = [NSString stringWithFormat:NSLocalizedString(@"Destroyed: %@", nil), [job.endProductionTime daysAgoStringWithTime:YES]];
							remainsColor = [UIColor colorWithNumber:AppearanceRedProgressColor];
							status = NSLocalizedString(@"Destroyed", nil);
						}
						else {
							remains = NSLocalizedString(@"Unknown Location", nil);
							remainsColor = [UIColor colorWithNumber:AppearanceRedProgressColor];
							status = NSLocalizedString(@"Unknown Status", nil);
						}
					}
					[charIDs addObject:charID];
					
					EVEDBRamActivity *activity = [EVEDBRamActivity ramActivityWithActivityID:job.activityID error:nil];
					
					NSDictionary* record = @{@"remains": remains,
							  @"remainsColor": remainsColor,
							  @"typeName": [NSString stringWithFormat:NSLocalizedString(@"%@ (%d runs)", nil), type.typeName, job.runs],
							  @"imageName": [type typeSmallImageName],
							  @"location": location,
							  @"charID": charID,
							  @"characterName": @"",
							  @"activityName": activity.activityName,
							  @"activityImageName": activity.iconImageName,
							  @"startTime": [dateFormatter stringFromDate:job.installTime],
							  @"type": type,
							  @"job": job,
							  @"status": status,
							  @"progress": @(progress)};
					if (finished)
						[finishedJobsTmp addObject:[NSMutableDictionary dictionaryWithDictionary:record]];
					else
						[activeJobsTmp addObject:[NSMutableDictionary dictionaryWithDictionary:record]];
				}
				
				[activeJobsTmp sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"job.endProductionTime" ascending:YES]]];
				[finishedJobsTmp sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"job.endProductionTime" ascending:NO]]];
				
				weakOperation.progress = 0.75;
				if (charIDs.count > 0) {
					NSError *error = nil;
					EVECharacterName *characterNames = [EVECharacterName characterNameWithIDs:[charIDs allObjects] error:&error progressHandler:nil];
					if (!error) {
						for (NSArray* jobs in @[activeJobsTmp, finishedJobsTmp]) {
							for (NSMutableDictionary *job in jobs) {
								NSString *charID = [job valueForKey:@"charID"];
								NSString *charName = [characterNames.characters valueForKey:charID];
								if (!charName)
									charName = @"";
								[job setValue:charName forKey:@"characterName"];
							}
						}
					}
				}
				weakOperation.progress = 1.0;
				[filterTmp updateWithValues:activeJobsTmp];
				[filterTmp updateWithValues:finishedJobsTmp];
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
				[currentActiveJobs addObjectsFromArray:activeJobsTmp];
				[currentFinishedJobs addObjectsFromArray:finishedJobsTmp];
				if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate)
					[self reloadJobs];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		EUFilter *filter = corporate ? self.corpFilter : self.charFilter;
		NSMutableArray *activeJobsTmp = [NSMutableArray array];
		NSMutableArray *finishedJobsTmp = [NSMutableArray array];
		if (filter) {
			EUOperation *operation = [EUOperation operationWithIdentifier:@"IndustryJobsViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				[activeJobsTmp addObjectsFromArray:[filter applyToValues:currentActiveJobs]];
				[finishedJobsTmp addObjectsFromArray:[filter applyToValues:currentFinishedJobs]];
			}];
			
			[operation setCompletionBlockInMainThread:^(void) {
				if (![weakOperation isCancelled]) {
					if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						self.activeJobs = activeJobsTmp;
						self.finishedJobs = finishedJobsTmp;
						[self searchWithSearchString:self.searchBar.text];
						[self.tableView reloadData];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			self.activeJobs = currentActiveJobs;
			self.finishedJobs = currentFinishedJobs;
		}
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
			self.activeJobs = nil;
			self.finishedJobs = nil;
			self.charActiveJobs = nil;
			self.charFinishedJobs = nil;
			self.corpActiveJobs = nil;
			self.corpFinishedJobs = nil;
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
		self.activeJobs = nil;
		self.finishedJobs = nil;
		self.charActiveJobs = nil;
		self.charFinishedJobs = nil;
		self.corpActiveJobs = nil;
		self.corpFinishedJobs = nil;
		self.filteredValues = nil;
		self.conquerableStations = nil;
		self.charFilter = nil;
		self.corpFilter = nil;
		[self reloadJobs];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if ((self.activeJobs.count == 0 && self.finishedJobs.count == 0) || !aSearchString)
		return;
	
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	EUOperation *operation = [EUOperation operationWithIdentifier:@"IndustryJobsViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NSMutableArray* jobs = [NSMutableArray arrayWithArray:self.activeJobs];
		[jobs addObjectsFromArray:self.finishedJobs];
		for (NSDictionary *job in jobs) {
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