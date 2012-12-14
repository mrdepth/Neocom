//
//  POSesViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "POSesViewController.h"
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"
#import "POSCellView.h"
#import "UITableViewCell+Nib.h"
#import "UIAlertView+Error.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "SelectCharacterBarButtonItem.h"
#import "POSViewController.h"
#import "NSString+TimeLeft.h"
#import "NSArray+GroupBy.h"

@interface POSesViewController(Private)
- (void) loadData;
- (void) loadStarbaseDetailForStarbase:(NSMutableDictionary *)pos account:(EVEAccount*) account;
- (NSDictionary*) sovereigntySolarSystems;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
- (IBAction) onClose:(id) sender;
@end

@implementation POSesViewController
@synthesize posesTableView;
@synthesize searchBar;

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
	self.title = NSLocalizedString(@"POS'es", nil);
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:searchBar] autorelease]];
	else
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	[self loadData];
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
	self.posesTableView = nil;
	self.searchBar = nil;
	@synchronized(self) {
		[poses release];
		[sections release];
		[filteredValues release];
		[sovereigntySolarSystems release];
		poses = sections = filteredValues = nil;
		sovereigntySolarSystems = nil;
	}
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[posesTableView release];
	[searchBar release];
	[poses release];
	[sections release];
	[sovereigntySolarSystems release];
	[filteredValues release];

    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return 1;
	else
		return sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	@synchronized(self) {
		if (tableView == self.searchDisplayController.searchResultsTableView)
			return filteredValues.count;
		else
			return [[sections objectAtIndex:section] count];
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	@synchronized(self) {
		if (tableView == self.searchDisplayController.searchResultsTableView)
			return nil;
		else
			return [[[sections objectAtIndex:section] objectAtIndex:0] valueForKeyPath:@"solarSystem.region.regionName"];
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"POSCellView";
	
    POSCellView *cell = (POSCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSString *nibName;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			nibName = tableView == posesTableView ? @"POSCellView" : @"POSCellViewCompact";
		else
			nibName = @"POSCellView";

        cell = [POSCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *pos;
	@synchronized(self) {
		if (tableView == self.searchDisplayController.searchResultsTableView)
			pos = [filteredValues objectAtIndex:indexPath.row];
		else
			pos = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];//[poses objectAtIndex:indexPath.row];
	}
	if (!pos)
		return cell;
	@synchronized(pos) {
		EVEDBInvType *controlTower = [pos valueForKey:@"controlTower"];
		cell.typeNameLabel.text = controlTower.typeName;
		cell.locationLabel.text = [pos valueForKey:@"location"];
		cell.stateLabel.text = [pos valueForKey:@"state"];
		cell.stateLabel.textColor = [pos valueForKey:@"stateColor"];
		cell.iconImageView.image = [UIImage imageNamed:[controlTower typeSmallImageName]];
		cell.fuelRemainsLabel.text = [pos valueForKey:@"remains"];
		UIColor *remainsColor = [pos valueForKey:@"remainsColor"];
		if (remainsColor)
			cell.fuelRemainsLabel.textColor = remainsColor;
		
		NSString *fuelImageName = [pos valueForKey:@"fuelImageName"];
		if (fuelImageName)
			cell.fuelImageView.image = [UIImage imageNamed:fuelImageName];
		else
			cell.fuelImageView.image = nil;
	}
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = tableView == self.searchDisplayController.searchResultsTableView ? nil : [self tableView:tableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return tableView == posesTableView ? 37 : 73;
	else
		return 73;
}


- (void)tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *pos;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		pos = [filteredValues objectAtIndex:indexPath.row];
	}
	else {
		pos = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	}

	POSViewController *controller = [[POSViewController alloc] initWithNibName:@"POSViewController" bundle:nil];
	
	controller.posID = [[pos valueForKey:@"posID"] longLongValue];
	controller.controlTowerType = [pos valueForKey:@"controlTower"];
	controller.solarSystem = [pos valueForKey:@"solarSystem"];
	controller.sovereigntyBonus = [[pos valueForKey:@"sovereigntyBonus"] floatValue];
	controller.location = [pos valueForKey:@"location"];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[controller.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)] autorelease]];
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
	else {
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]] autorelease];
		tableView.backgroundView.contentMode = UIViewContentModeTop;
	}	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}


@end

@implementation POSesViewController(Private)

- (void) loadData {
	NSMutableArray *posesTmp = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];

	NSMutableArray *sectionsTmp = [NSMutableArray array];

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"POSesViewController+Load" name:NSLocalizedString(@"Loading POS'es", nil)];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSError *error = nil;
		EVEStarbaseList *starbaseList = [EVEStarbaseList starbaseListWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID error:&error];
		operation.progress = 0.25;
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			[self sovereigntySolarSystems];
			operation.progress = 0.5;
			EVEAccount *account = [EVEAccount currentAccount];
			
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
			
			NSDate *currentTime = [starbaseList serverTimeWithLocalTime:[NSDate date]];
			float n = starbaseList.starbases.count;
			float i = 0;
			for (EVEStarbaseListItem *starbase in starbaseList.starbases) {
				if ([operation isCancelled])
					break;

				EVEDBInvType *controlTower = [EVEDBInvType invTypeWithTypeID:starbase.typeID error:nil];
				EVEDBMapSolarSystem *solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:starbase.locationID error:nil];
				EVEDBMapDenormalize *moon = [EVEDBMapDenormalize mapDenormalizeWithItemID:starbase.moonID error:nil];
				NSString *state;
				NSString *location;
				UIColor *stateColor;
				
				if (moon)
					location = [NSString stringWithFormat:@"%@ / %@", moon.itemName, solarSystem.solarSystemName];
				else
					location = solarSystem.solarSystemName;
				
				switch (starbase.state) {
					case EVEPOSStateUnanchored:
						state = NSLocalizedString(@"Unanchored", nil);
						stateColor = [UIColor yellowColor];
						break;
					case EVEPOSStateAnchoredOffline:
						state = NSLocalizedString(@"Anchored / Offline", nil);
						stateColor = [UIColor redColor];
						break;
					case EVEPOSStateOnlining: {
						NSMutableString *remains = [NSMutableString string];
						int sec = (int) [starbase.onlineTimestamp timeIntervalSinceDate:currentTime];
						int days = sec / (60 * 60 * 24);
						sec %= (60 * 60 * 24);
						int hours = sec / (60 * 60);
						sec %= (60 * 60);
						int mins = sec / 60;
						sec %= 60;
						if (days)
							[remains appendFormat:@"%dd ", days];
						if (hours)
							[remains appendFormat:@"%dh ", hours];
						if (mins)
							[remains appendFormat:@"%dm ", mins];
						if (sec)
							[remains appendFormat:@"%ds", sec];
						
						state = [NSString stringWithFormat:NSLocalizedString(@"Onlining: %@ remains", nil), remains];
						stateColor = [UIColor yellowColor];
						break;
					}
					case EVEPOSStateReinforced: {
						NSMutableString *remains = [NSMutableString string];
						int sec = (int) [starbase.stateTimestamp timeIntervalSinceDate:currentTime];
						int days = sec / (60 * 60 * 24);
						sec %= (60 * 60 * 24);
						int hours = sec / (60 * 60);
						sec %= (60 * 60);
						int mins = sec / 60;
						sec %= 60;
						if (days)
							[remains appendFormat:@"%dd ", days];
						if (hours)
							[remains appendFormat:@"%dh ", hours];
						if (mins)
							[remains appendFormat:@"%dm ", mins];
						if (sec)
							[remains appendFormat:@"%ds", sec];
						
						state = [NSString stringWithFormat:NSLocalizedString(@"Reinforced: %@ remains", nil), remains];
						stateColor = [UIColor redColor];
						break;
					}
					case EVEPOSStateOnline:
						state = [NSString stringWithFormat:NSLocalizedString(@"Online: since %@", nil), [dateFormatter stringFromDate:starbase.onlineTimestamp]];
						stateColor = [UIColor greenColor];
						break;
					default:
						break;
				}
				NSMutableDictionary *row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											controlTower, @"controlTower",
											location, @"location",
											state, @"state",
											stateColor, @"stateColor",
											solarSystem, @"solarSystem",
											[NSNumber numberWithLongLong:starbase.itemID], @"posID",
											nil];
				[posesTmp addObject:row];
				EUOperation *loadDetailsOperation = [EUOperation operationWithIdentifier:nil name:NSLocalizedString(@"Loading POS Details", nil)];
				[loadDetailsOperation addExecutionBlock:^{
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					[self loadStarbaseDetailForStarbase:row account:account];
					[pool release];
				}];
				[loadDetailsOperation addDependency:operation];
				[[EUOperationQueue sharedQueue] addOperation:loadDetailsOperation];
				operation.progress = 0.5 + i++ / n / 2.0;
				
			}
			[dateFormatter release];
			[posesTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"location" ascending:YES]]];
			[sectionsTmp addObjectsFromArray:[posesTmp arrayGroupedByKey:@"solarSystem.region.regionName"]];
			[sectionsTmp sortUsingComparator:^(id obj1, id obj2) {
				return [[[obj1 objectAtIndex:0] valueForKeyPath:@"solarSystem.region.regionName"] compare:[[obj2 objectAtIndex:0] valueForKeyPath:@"solarSystem.region.regionName"]];
			}];
		}
		
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![operation isCancelled]) {
			[poses release];
			poses = [posesTmp retain];
			[sections release];
			sections = [sectionsTmp retain];
			[posesTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) loadStarbaseDetailForStarbase:(NSMutableDictionary *)pos account:(EVEAccount*) account {
	NSError *error = nil;
	//EVEStarbaseDetail *starbaseDetail = [EVEStarbaseDetail starbaseDetailWithUserID:character.userID apiKey:character.apiKey characterID:character.characterID itemID:[[pos valueForKey:@"posID"] longLongValue] error:&error];
	EVEStarbaseDetail *starbaseDetail = [EVEStarbaseDetail starbaseDetailWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID itemID:[[pos valueForKey:@"posID"] longLongValue] error:&error];

	if (!error) {
		NSUInteger section = NSNotFound;
		NSUInteger row = NSNotFound;
		@synchronized(self) {
			NSString *regionName = [pos valueForKeyPath:@"solarSystem.region.regionName"];
			section = [sections indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
				if ([[[obj objectAtIndex:0] valueForKeyPath:@"solarSystem.region.regionName"] isEqualToString:regionName]) {
					*stop = YES;
					return YES;
				}
				else
					return NO;
			}];
			
			if (section != NSNotFound) {
				NSArray *array = [sections objectAtIndex:section];
				row = [array indexOfObject:pos];
			}
		}
		NSIndexPath *indexPath;
		if (row != NSNotFound && section != NSNotFound)
			indexPath = [NSIndexPath indexPathForRow:row inSection:section];
		else
			indexPath = nil;
		
		float hours = [[starbaseDetail serverTimeWithLocalTime:[NSDate date]] timeIntervalSinceDate:starbaseDetail.currentTime] / 3600.0;
		if (hours < 0)
			hours = 0;
		EVEDBInvControlTowerResource *minResource = nil;
		int minRemains = INT_MAX;
		int minQuantity = 0;
		EVEDBInvType *controlTowerType = [pos valueForKey:@"controlTower"];
		EVEDBMapSolarSystem *solarSystem = [pos valueForKey:@"solarSystem"];
		
		float bonus;
		NSDictionary *sovSolarSystems = [self sovereigntySolarSystems];
		if (sovSolarSystems &&
			account.characterSheet.allianceID != 0 &&
			account.characterSheet.allianceID == [[sovSolarSystems valueForKey:[NSString stringWithFormat:@"%d", solarSystem.solarSystemID]] allianceID])
			bonus = 0.75;
		else
			bonus = 1;
		
		
		for (EVEDBInvControlTowerResource *resource in [controlTowerType resources]) {
			if (resource.purposeID != 1 ||
				(resource.minSecurityLevel > 0 && solarSystem.security < resource.minSecurityLevel) ||
				(resource.factionID > 0 && solarSystem.region.factionID != resource.factionID))
				continue;
			
			int quantity = 0;
			for (EVEStarbaseDetailFuelItem *item in starbaseDetail.fuel) {
				if (item.typeID == resource.resourceTypeID) {
					quantity = item.quantity - hours * round(resource.quantity * bonus);
					break;
				}
			}
			int remains = quantity / round(resource.quantity * bonus) * 3600;
			if (remains < minRemains) {
				minResource = resource;
				minRemains = remains;
				minQuantity = quantity;
			}
		}
		
		UIColor *remainsColor;
		NSString *remains;
		if (minQuantity > 0) {
			if (minRemains > 3600 * 24)
				remainsColor = [UIColor greenColor];
			else if (minRemains > 3600)
				remainsColor = [UIColor yellowColor];
			else
				remainsColor = [UIColor redColor];
			remains = [NSString stringWithTimeLeft:minRemains];
		}
		else {
			remainsColor = [UIColor redColor];
			remains = @"0s";
		}
		@synchronized(pos) {
			[pos setValue:remainsColor forKey:@"remainsColor"];
			[pos setValue:remains forKeyPath:@"remains"];
			[pos setValue:[NSNumber numberWithFloat:bonus] forKey:@"sovereigntyBonus"];
			[pos setValue:[minResource.resourceType typeSmallImageName] forKey:@"fuelImageName"];
		}

		if (indexPath) {
			[[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
				[posesTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			}];
		}
		
		NSUInteger index = [filteredValues indexOfObject:pos];
		if (filteredValues && index != NSNotFound) {
			indexPath = [NSIndexPath indexPathForRow:index inSection:0];
			[[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
				[self.searchDisplayController.searchResultsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			}];
		}
	}
}

- (NSDictionary*) sovereigntySolarSystems {
	@synchronized(self) {
		if (!sovereigntySolarSystems) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			sovereigntySolarSystems = [[NSMutableDictionary alloc] init];
			NSError *error = nil;
			EVESovereignty *sovereignty = [EVESovereignty sovereigntyWithError:&error];
			if (!error) {
				for (EVESovereigntyItem *solarSystem in sovereignty.solarSystems)
					[sovereigntySolarSystems setValue:solarSystem forKey:[NSString stringWithFormat:@"%d", solarSystem.solarSystemID]];
			}
			[pool release];
		}
		return sovereigntySolarSystems;
	}
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	if (!account)
		[self.navigationController popToRootViewControllerAnimated:YES];
	else {
		@synchronized (self) {
			[poses release];
			[filteredValues release];
			poses = filteredValues = nil;
		}
		[self loadData];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (poses.count == 0)
		return;
	
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"POSesViewController+Filter" name:NSLocalizedString(@"Searching...", nil)];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		for (NSDictionary *pos in poses) {
			if (([pos valueForKey:@"location"] && [[pos valueForKey:@"location"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([pos valueForKey:@"state"] && [[pos valueForKey:@"state"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([pos valueForKey:@"controlTower"] && [[[pos valueForKey:@"controlTower"] typeName] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([pos valueForKey:@"solarSystem"] && [[[[pos valueForKey:@"solarSystem"] region] regionName] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
				[filteredValuesTmp addObject:pos];
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
