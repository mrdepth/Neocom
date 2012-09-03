//
//  AssetContentsViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AssetContentsViewController.h"
#import "EVEOnlineAPI.h"
#import "EVEDBAPI.h"
#import "NibTableViewCell.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "SelectCharacterBarButtonItem.h"
#import "UIAlertView+Error.h"
#import "ItemCellView.h"
#import "NSArray+GroupBy.h"
#import "EVEAssetListItem+AssetsViewController.h"
#import "ItemViewController.h"
#import "FittingViewController.h"
#import "POSFittingViewController.h"
#import "CharacterEVE.h"
#import "Fit.h"
#import "POSFit.h"

@interface AssetContentsViewController(Private)
- (void) reloadAssets;
- (void) searchWithSearchString:(NSString*) searchString;
- (IBAction)onClose:(id)sender;
@end

@implementation AssetContentsViewController
@synthesize assetsTableView;
@synthesize searchBar;
@synthesize filterViewController;
@synthesize filterNavigationViewController;
@synthesize filterPopoverController;
@synthesize asset;
@synthesize corporate;

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
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.filterPopoverController = [[[UIPopoverController alloc] initWithContentViewController:filterNavigationViewController] autorelease];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
	}
	if (asset.type.group.categoryID == 6 || asset.type.groupID == eufe::CONTROL_TOWER_GROUP_ID) // Ship or Control Tower
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Open fit" style:UIBarButtonItemStyleBordered target:self action:@selector(onOpenFit:)] autorelease];
	EVEAccount* account = [EVEAccount currentAccount];
	
	
	if (asset.location.itemName) {
		self.title = asset.location.itemName;
	}
	else {
		self.title = asset.name;
		__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"AssetContentsViewController+LoadLocation"];
		[operation addExecutionBlock:^(void) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			EVELocations* locations = nil;
			if (corporate && account.corpAccessMask & 16777216)
				locations = [EVELocations locationsWithKeyID:account.corpKeyID
													   vCode:account.corpVCode
												 characterID:account.characterID
														 ids:[NSArray arrayWithObject:[NSNumber numberWithLongLong:asset.itemID]]
												   corporate:YES
													   error:nil];
			else if (!corporate && account.charAccessMask & 134217728)
				locations = [EVELocations locationsWithKeyID:account.charKeyID
													   vCode:account.charVCode
												 characterID:account.characterID
														 ids:[NSArray arrayWithObject:[NSNumber numberWithLongLong:asset.itemID]]
												   corporate:NO
													   error:nil];
			if (locations.locations.count == 1)
				asset.location = [locations.locations objectAtIndex:0];
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^(void) {
			if (![operation isCancelled]) {
				if (asset.location)
					self.title = asset.location.itemName;
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
		
	
	[self reloadAssets];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
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
	self.assetsTableView = nil;
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	[assets release];
	[filteredValues release];
	assets = filteredValues = nil;
}


- (void)dealloc {
	[assetsTableView release];
	[searchBar release];
	[filteredValues release];
	[assets release];
	[filterViewController release];
	[filterNavigationViewController release];
	[filterPopoverController release];
	[asset release];
    [super dealloc];
}

- (IBAction)onOpenFit:(id)sender {
	if (asset.type.group.categoryID == 6) {// Ship
		FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"FittingViewController-iPad" : @"FittingViewController")
																							   bundle:nil];
		__block EUSingleBlockOperation* operation = [EUSingleBlockOperation operationWithIdentifier:@"AssetContentsViewController+OpenFit"];
		__block Fit* fit = nil;
		__block eufe::Character* character = NULL;
		
		[operation addExecutionBlock:^{
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			
			character = new eufe::Character(fittingViewController.fittingEngine);
			
			EVEAccount* currentAccount = [EVEAccount currentAccount];
			if (currentAccount && currentAccount.charKeyID && currentAccount.charVCode && currentAccount.characterID) {
				CharacterEVE* eveCharacter = [CharacterEVE characterWithCharacterID:currentAccount.characterID keyID:currentAccount.charKeyID vCode:currentAccount.charVCode name:currentAccount.characterName];
				character->setCharacterName([eveCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
				character->setSkillLevels(*[eveCharacter skillsMap]);
			}
			else
				character->setCharacterName("All Skills 0");
			fit = [[Fit alloc] initWithAsset:asset character:character];
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
			if (![operation isCancelled]) {
				fittingViewController.fittingEngine->getGang()->addPilot(character);
				fittingViewController.fit = fit;
				[fittingViewController.fits addObject:fit];
				[self.navigationController pushViewController:fittingViewController animated:YES];
			}
			else {
				if (character)
					delete character;
			}
			[fittingViewController release];
			[fit release];
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		POSFittingViewController *posFittingViewController = [[POSFittingViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"POSFittingViewController-iPad" : @"POSFittingViewController")
																										bundle:nil];
		__block EUSingleBlockOperation* operation = [EUSingleBlockOperation operationWithIdentifier:@"AssetContentsViewController+OpenFit"];
		__block POSFit* fit = nil;
		
		[operation addExecutionBlock:^{
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			
			fit = [[POSFit alloc] initWithAsset:asset engine:posFittingViewController.fittingEngine];
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
			if (![operation isCancelled]) {
				posFittingViewController.fit = fit;
				[self.navigationController pushViewController:posFittingViewController animated:YES];
			}
			[posFittingViewController release];
			[fit release];
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return [filteredValues count];
	else {
		return [sections count];
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return [[[filteredValues objectAtIndex:section] valueForKey:@"assets"] count];
	else
		return [[[sections objectAtIndex:section] valueForKey:@"assets"] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"ItemCellView";
	
    ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	EVEAssetListItem* item;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		item = [[[filteredValues objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	else
		item = [[[sections objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	
	cell.iconImageView.image = [UIImage imageNamed:item.type.typeSmallImageName];
	
	if (item.parent && item.parent != asset) {
		cell.titleLabel.numberOfLines = 2;
		cell.titleLabel.text = [NSString stringWithFormat:@"%@\nIn: %@", item.name, item.parent.name];
	}
	else {
		cell.titleLabel.numberOfLines = 1;
		cell.titleLabel.text = item.name;
	}

	cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return [[filteredValues objectAtIndex:section] valueForKey:@"title"];
	else
		return [[sections objectAtIndex:section] valueForKey:@"title"];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	EVEAssetListItem* item;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		item = [[[filteredValues objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	else
		item = [[[sections objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemViewController-iPad" : @"ItemViewController")
																		  bundle:nil];
	
	controller.type = item.type;
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


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = [self tableView:tableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	EVEAssetListItem* item;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		item = [[[filteredValues objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	else
		item = [[[assets objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	
	if (item.contents.count > 0) {
		AssetContentsViewController* controller = [[AssetContentsViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"AssetContentsViewController-iPad" : @"AssetContentsViewController")
																								bundle:nil];
		controller.asset = item;
		controller.corporate = self.corporate;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"ItemViewController-iPad" : @"ItemViewController")
																			  bundle:nil];
		
		controller.type = item.type;
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

	
/*	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	EUMailMessage* message = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView)
		message = [[filteredValues objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	else
		message = [[messages objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	MessageViewController *controller = [[MessageViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"MessageViewController-iPad" : @"MessageViewController")
																				bundle:nil];
	controller.message = message;
	
	if (!message.read) {
		message.read = YES;
		[mailBox save];
		[self.messagesTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
		[self.searchDisplayController.searchResultsTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
		[[NSNotificationCenter defaultCenter] postNotificationName:NotificationReadMail object:mailBox];
	}
	
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
	[controller release];*/
}

#pragma mark ExpandedTableViewDelegate

- (void) tableView:(UITableView*) tableView didExpandSection:(NSInteger) section {
	if (tableView != self.searchDisplayController.searchResultsTableView)
		return [[sections objectAtIndex:section] setValue:[NSNumber numberWithBool:YES] forKey:@"expanded"];
}

- (void) tableView:(UITableView*) tableView didCollapseSection:(NSInteger) section {
	if (tableView != self.searchDisplayController.searchResultsTableView)
		return [[sections objectAtIndex:section] setValue:[NSNumber numberWithBool:NO] forKey:@"expanded"];
}

- (BOOL) tableView:(UITableView*) tableView isExpandedSection:(NSInteger) section {
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return YES;
	else
		return [[[sections objectAtIndex:section] valueForKey:@"expanded"] boolValue];
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
	[self reloadAssets];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

@end

@implementation AssetContentsViewController(Private)

- (void) reloadAssets {
	[sections release];
	sections = nil;
	if (!assets) {
		EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"assetsFilter" ofType:@"plist"]]];
		NSMutableArray* assetsTmp = [NSMutableArray array];
		__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"AssetContentsViewController+Load"];
		[operation addExecutionBlock:^(void) {
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			if (asset.type.group.categoryID == 6) { // Ship
				NSMutableArray* hiSlots = [NSMutableArray array];
				NSMutableArray* medSlots = [NSMutableArray array];
				NSMutableArray* lowSlots = [NSMutableArray array];
				NSMutableArray* rigSlots = [NSMutableArray array];
				NSMutableArray* subsystemSlots = [NSMutableArray array];
				NSMutableArray* droneBay = [NSMutableArray array];
				NSMutableArray* cargo = [NSMutableArray array];
				
				for (EVEAssetListItem* item in asset.contents) {
					if (item.flag >= EVEInventoryFlagHiSlot0 && item.flag <= EVEInventoryFlagHiSlot7)
						[hiSlots addObject:item];
					else if (item.flag >= EVEInventoryFlagMedSlot0 && item.flag <= EVEInventoryFlagMedSlot7)
						[medSlots addObject:item];
					else if (item.flag >= EVEInventoryFlagLoSlot0 && item.flag <= EVEInventoryFlagLoSlot7)
						[lowSlots addObject:item];
					else if (item.flag >= EVEInventoryFlagRigSlot0 && item.flag <= EVEInventoryFlagRigSlot7)
						[rigSlots addObject:item];
					else if (item.flag >= EVEInventoryFlagSubSystem0 && item.flag <= EVEInventoryFlagSubSystem7)
						[subsystemSlots addObject:item];
					else if (item.flag == EVEInventoryFlagDroneBay)
						[droneBay addObject:item];
					else
						[cargo addObject:item];
				}
				
				NSString* titles[] = {@"High power slots", @"Medium power slots", @"Low power slots", @"Rig power slots", @"Sub system slots", @"Drone bay", @"Cargo"};
				NSArray* arrays[] = {hiSlots, medSlots, lowSlots, rigSlots, subsystemSlots, droneBay, cargo};
				for (int i = 0; i < 7; i++) {
					NSArray* array = arrays[i];
					if (array.count > 0)
						[assetsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
											  titles[i], @"title",
											  [NSNumber numberWithBool:YES], @"expanded",
											  arrays[i], @"assets", nil]];
				}
				
			}
			else if (asset.type.groupID == 471) { //Hangar or Office
				NSMutableArray* groups = [NSMutableArray arrayWithArray:[asset.contents arrayGroupedByKey:@"flag"]];
				
				[groups sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
					EVEAssetListItem* asset1 = [obj1 objectAtIndex:0];
					EVEAssetListItem* asset2 = [obj2 objectAtIndex:0];
					if (asset1.flag > asset2.flag)
						return NSOrderedDescending;
					else if (asset2.flag < asset2.flag)
						return NSOrderedAscending;
					else
						return NSOrderedSame;
				}];
				
				for (NSArray* group in groups) {
					NSString* title;
					EVEInventoryFlag flag = [[group objectAtIndex:0] flag];
					if (flag == EVEInventoryFlagHangar)
						title = @"Hangar 1";
					else if (flag >= EVEInventoryFlagCorpSAG2 && flag <= EVEInventoryFlagCorpSAG7) {
						int i = flag - EVEInventoryFlagCorpSAG2 + 2;
						title = [NSString stringWithFormat:@"Hangar %d", i];
					}
					else
						title = @"Unknown hangar";
					group = [group sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
					if (group.count == 1)
						title = [title stringByAppendingString:@" (1 item)"];
					else
						title = [title stringByAppendingFormat:@" (%d items)", group.count];
					[assetsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										  title, @"title",
										  [NSNumber numberWithBool:YES], @"expanded",
										  group, @"assets", nil]];
				}
			}
			else if (asset.type.groupID == 363) { //Ship Maintenance Array
				NSMutableArray* groups = [NSMutableArray arrayWithArray:[asset.contents arrayGroupedByKey:@"type.groupID"]];
				
				[groups sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
					EVEAssetListItem* asset1 = [obj1 objectAtIndex:0];
					EVEAssetListItem* asset2 = [obj2 objectAtIndex:0];
					return [asset1.type.group.groupName compare:asset2.type.group.groupName];
				}];
				
				for (NSArray* group in groups) {
					EVEAssetListItem* item = [group objectAtIndex:0];
					NSString* title = item.type.group.groupName;
					group = [group sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
					[assetsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										  title, @"title",
										  [NSNumber numberWithBool:YES], @"expanded",
										  group, @"assets", nil]];
				}
			}
			else {
				NSMutableArray* groups = [NSMutableArray arrayWithArray:[asset.contents arrayGroupedByKey:@"type.group.categoryID"]];
				
				[groups sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
					EVEAssetListItem* asset1 = [obj1 objectAtIndex:0];
					EVEAssetListItem* asset2 = [obj2 objectAtIndex:0];
					return [asset1.type.group.category.categoryName compare:asset2.type.group.category.categoryName];
				}];
				
				for (NSArray* group in groups) {
					EVEAssetListItem* item = [group objectAtIndex:0];
					NSString* title = item.type.group.category.categoryName;
					group = [group sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
					[assetsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										  title, @"title",
										  [NSNumber numberWithBool:YES], @"expanded",
										  group, @"assets", nil]];
				}
			}
			
			__block void (^process)(EVEAssetListItem*);
			process = ^(EVEAssetListItem* item) {
				[filterTmp updateWithValue:item];
				for (EVEAssetListItem* subItem in item.contents)
					process(subItem);
			};
			
			for (EVEAssetListItem* item in asset.contents) {
				process(item);
			}
			
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
			if (![operation isCancelled]) {
				[assets release];
				assets = [assetsTmp retain];
				if (assets)
					[self reloadAssets];
				[filter release];
				filter = [filterTmp retain];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		NSMutableArray* sectionsTmp = [NSMutableArray array];
		if (filter.predicate) {
			__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"AssetContentsViewController+Filter"];
			[operation addExecutionBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

				__block void (^search)(NSArray*, NSMutableArray*);
				search = ^(NSArray* contents, NSMutableArray* location) {
					[location addObjectsFromArray:[filter applyToValues:contents]];
					for (EVEAssetListItem* item in contents)
						search(item.contents, location);
				};
				NSMutableArray* filteredAssets = [NSMutableArray array];
				for (NSDictionary* section in assets) {
					search([section valueForKey:@"assets"], filteredAssets);
				}

				if (filteredAssets.count > 0) {
					NSMutableArray* groups = [NSMutableArray arrayWithArray:[filteredAssets arrayGroupedByKey:@"type.group.categoryID"]];
					
					[groups sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
						EVEAssetListItem* asset1 = [obj1 objectAtIndex:0];
						EVEAssetListItem* asset2 = [obj2 objectAtIndex:0];
						return [asset1.type.group.category.categoryName compare:asset2.type.group.category.categoryName];
					}];
					
					for (NSArray* group in groups) {
						EVEAssetListItem* item = [group objectAtIndex:0];
						NSString* title = item.type.group.category.categoryName;
						group = [group sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
						[sectionsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
												title, @"title",
												[NSNumber numberWithBool:YES], @"expanded",
												group, @"assets", nil]];
					}
				}

				[pool release];
			}];
			
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![operation isCancelled]) {
					[sections release];
					sections = [sectionsTmp retain];
					[self searchWithSearchString:self.searchBar.text];
					[assetsTableView reloadData];
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			sections = [assets retain];
			[self searchWithSearchString:self.searchBar.text];
		}
	}
	[assetsTableView reloadData];
}


- (IBAction) onClose:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (sections.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"AssetContentsViewController+Search"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		__block void (^search)(NSArray*, NSMutableArray*);
		
		search = ^(NSArray* contents, NSMutableArray* values) {
			for (EVEAssetListItem* item in contents) {
				if ([item.name rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					[item.type.typeName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					[item.type.group.groupName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					[item.type.group.category.categoryName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					(item.location.itemName && [item.location.itemName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
					[values addObject:item];
				if (asset.contents.count > 0)
					search(item.contents, values);
			}
		};
		
		
		NSMutableArray* values = [[NSMutableArray alloc] init];
		for (NSDictionary* section in sections) {
			search([section valueForKey:@"assets"], values);
		}
		NSMutableArray* values2 =[NSMutableArray arrayWithArray:[filter applyToValues:values]];
		[values release];
		
		if (values2.count > 0) {
			NSMutableArray* groups = [NSMutableArray arrayWithArray:[values2 arrayGroupedByKey:@"type.group.categoryID"]];
			[values2 sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];

			[groups sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				EVEAssetListItem* asset1 = [obj1 objectAtIndex:0];
				EVEAssetListItem* asset2 = [obj2 objectAtIndex:0];
				return [asset1.type.group.category.categoryName compare:asset2.type.group.category.categoryName];
			}];
			
			for (NSArray* group in groups) {
				EVEAssetListItem* item = [group objectAtIndex:0];
				NSString* title = item.type.group.category.categoryName;
				group = [group sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
				[filteredValuesTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
											  title, @"title",
											  [NSNumber numberWithBool:YES], @"expanded",
											  group, @"assets", nil]];
			}
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