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
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "SelectCharacterBarButtonItem.h"
#import "UIAlertView+Error.h"
#import "GroupedCell.h"
#import "NSArray+GroupBy.h"
#import "EVEAssetListItem+AssetsViewController.h"
#import "ItemViewController.h"
#import "FittingViewController.h"
#import "POSFittingViewController.h"
#import "FitCharacter.h"
#import "ShipFit.h"
#import "POSFit.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "appearance.h"

@interface AssetContentsViewController()
@property (nonatomic, strong) NSMutableArray *filteredValues;
@property (nonatomic, strong) NSArray *assets;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) EUFilter *filter;

- (void) reloadAssets;
- (void) searchWithSearchString:(NSString*) searchString;
- (IBAction)onClose:(id)sender;
@end

@implementation AssetContentsViewController


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
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.filterPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.filterNavigationViewController];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
	}
	if (self.asset.type.group.categoryID == 6 || self.asset.type.groupID == eufe::CONTROL_TOWER_GROUP_ID) // Ship or Control Tower
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Open fit", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onOpenFit:)];
	EVEAccount* account = [EVEAccount currentAccount];
	
	
	if (self.asset.location.itemName) {
		self.title = self.asset.location.itemName;
	}
	else {
		self.title = self.asset.name;
		EUOperation *operation = [EUOperation operationWithIdentifier:@"AssetContentsViewController+LoadLocation" name:NSLocalizedString(@"Loading Locations", nil)];
		__weak EUOperation* weakOperation = operation;
		[operation addExecutionBlock:^(void) {
			EVELocations* locations = nil;
			if (self.corporate && account.corpAPIKey.apiKeyInfo.key.accessMask & 16777216)
				locations = [EVELocations locationsWithKeyID:account.corpAPIKey.keyID
													   vCode:account.corpAPIKey.vCode
												 characterID:account.character.characterID
														 ids:[NSArray arrayWithObject:[NSNumber numberWithLongLong:self.asset.itemID]]
												   corporate:YES
													   error:nil
											 progressHandler:nil];
			else if (!self.corporate && account.charAPIKey.apiKeyInfo.key.accessMask & 134217728)
				locations = [EVELocations locationsWithKeyID:account.charAPIKey.keyID
													   vCode:account.charAPIKey.vCode
												 characterID:account.character.characterID
														 ids:[NSArray arrayWithObject:[NSNumber numberWithLongLong:self.asset.itemID]]
												   corporate:NO
													   error:nil
											 progressHandler:nil];
			if (locations.locations.count == 1)
				self.asset.location = [locations.locations objectAtIndex:0];
		}];
		
		[operation setCompletionBlockInMainThread:^(void) {
			if (![weakOperation isCancelled]) {
				if (self.asset.location)
					self.title = self.asset.location.itemName;
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
		
	
	[self reloadAssets];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self becomeFirstResponder];
}

- (BOOL) canBecomeFirstResponder {
	return YES;
}

- (void) motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	if (motion == UIEventSubtypeMotionShake)
		[(CollapsableTableView*) self.tableView handleShake];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	self.assets = nil;
	self.filteredValues = nil;
}

- (IBAction)onOpenFit:(id)sender {
	if (self.asset.type.group.categoryID == 6) {// Ship
		FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
		__block EUOperation* operation = [EUOperation operationWithIdentifier:@"AssetContentsViewController+OpenFit" name:NSLocalizedString(@"Loading Ship Fit", nil)];
		__weak EUOperation* weakOperation = operation;
		__block ShipFit* fit = nil;
		__block eufe::Character* character = NULL;
		
		[operation addExecutionBlock:^{
			character = new eufe::Character(fittingViewController.fittingEngine);
			
			EVEAccount* currentAccount = [EVEAccount currentAccount];
			weakOperation.progress = 0.3;
			if (currentAccount.characterSheet) {
				FitCharacter* fitCharacter = [FitCharacter fitCharacterWithAccount:currentAccount];
				character->setCharacterName([fitCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
				character->setSkillLevels(*[fitCharacter skillsMap]);
			}
			else
				character->setCharacterName([NSLocalizedString(@"All Skills 0", nil) UTF8String]);
			weakOperation.progress = 0.6;
			fit = [ShipFit shipFitWithAsset:self.asset character:character];
			weakOperation.progress = 1.0;
		}];
		
		[operation setCompletionBlockInMainThread:^{
			if (![weakOperation isCancelled]) {
				fittingViewController.fittingEngine->getGang()->addPilot(character);
				fittingViewController.fit = fit;
				[fittingViewController.fits addObject:fit];
				[self.navigationController pushViewController:fittingViewController animated:YES];
			}
			else {
				if (character)
					delete character;
			}
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		POSFittingViewController *posFittingViewController = [[POSFittingViewController alloc] initWithNibName:@"POSFittingViewController" bundle:nil];
		__block EUOperation* operation = [EUOperation operationWithIdentifier:@"AssetContentsViewController+OpenFit" name:NSLocalizedString(@"Loading POS Fit", nil)];
		__weak EUOperation* weakOperation = operation;
		__block POSFit* fit = nil;
		
		[operation addExecutionBlock:^{
			fit = [POSFit posFitWithAsset:self.asset engine:posFittingViewController.fittingEngine];
		}];
		
		[operation setCompletionBlockInMainThread:^{
			if (![weakOperation isCancelled]) {
				posFittingViewController.fit = fit;
				[self.navigationController pushViewController:posFittingViewController animated:YES];
			}
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return [self.filteredValues count];
	else {
		return [self.sections count];
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return [[[self.filteredValues objectAtIndex:section] valueForKey:@"assets"] count];
	else
		return [[[self.sections objectAtIndex:section] valueForKey:@"assets"] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	EVEAssetListItem* item;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		item = [[[self.filteredValues objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	else
		item = [[[self.sections objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	
	cell.imageView.image = [UIImage imageNamed:item.type.typeSmallImageName];
	
	if (item.parent && item.parent != self.asset) {
		cell.textLabel.numberOfLines = 2;
		cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@\nIn: %@", nil), item.name, item.parent.name];
	}
	else {
		cell.textLabel.numberOfLines = 1;
		cell.textLabel.text = item.name;
	}

	cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	int groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView)
		return [[self.filteredValues objectAtIndex:section] valueForKey:@"title"];
	else
		return [[self.sections objectAtIndex:section] valueForKey:@"title"];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	EVEAssetListItem* item;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		item = [[[self.filteredValues objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	else
		item = [[[self.sections objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = item.type;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:navController animated:YES];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
}


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
	return 40;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	EVEAssetListItem* item;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		item = [[[self.filteredValues objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	else
		item = [[[self.assets objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	
	if (item.contents.count > 0) {
		AssetContentsViewController* controller = [[AssetContentsViewController alloc] initWithNibName:@"AssetContentsViewController" bundle:nil];
		controller.asset = item;
		controller.corporate = self.corporate;
		[self.navigationController pushViewController:controller animated:YES];
	}
	else {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		
		controller.type = item.type;
		[controller setActivePage:ItemViewControllerActivePageInfo];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navController animated:YES];
		}
		else
			[self.navigationController pushViewController:controller animated:YES];
	}
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
	self.filterViewController.filter = self.filter;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.filterPopoverController presentPopoverFromRect:self.searchBar.frame inView:[self.searchBar superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	else
		[self presentModalViewController:self.filterNavigationViewController animated:YES];
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

#pragma mark - Private

- (void) reloadAssets {
	self.sections = nil;
	if (!self.assets) {
		EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"assetsFilter" ofType:@"plist"]]];
		NSMutableArray* assetsTmp = [NSMutableArray array];
		__block EUOperation *operation = [EUOperation operationWithIdentifier:@"AssetContentsViewController+Load" name:NSLocalizedString(@"Loading Assets", nil)];
		__weak EUOperation* weakOperation = operation;
		[operation addExecutionBlock:^(void) {
			if (self.asset.type.group.categoryID == 6) { // Ship
				NSMutableArray* hiSlots = [NSMutableArray array];
				NSMutableArray* medSlots = [NSMutableArray array];
				NSMutableArray* lowSlots = [NSMutableArray array];
				NSMutableArray* rigSlots = [NSMutableArray array];
				NSMutableArray* subsystemSlots = [NSMutableArray array];
				NSMutableArray* droneBay = [NSMutableArray array];
				NSMutableArray* cargo = [NSMutableArray array];
				
				for (EVEAssetListItem* item in self.asset.contents) {
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
				
				NSString* titles[] = {
					NSLocalizedString(@"High power slots", nil),
					NSLocalizedString(@"Medium power slots", nil),
					NSLocalizedString(@"Low power slots", nil),
					NSLocalizedString(@"Rig power slots", nil),
					NSLocalizedString(@"Sub system slots", nil),
					NSLocalizedString(@"Drone bay", nil),
					NSLocalizedString(@"Cargo", nil)};
				NSArray* arrays[] = {hiSlots, medSlots, lowSlots, rigSlots, subsystemSlots, droneBay, cargo};
				for (int i = 0; i < 7; i++) {
					NSArray* array = arrays[i];
					if (array.count > 0)
						[assetsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
											  titles[i], @"title",
											  [NSNumber numberWithBool:NO], @"collapsed",
											  arrays[i], @"assets", nil]];
				}
				
			}
			else if (self.asset.type.groupID == 471) { //Hangar or Office
				NSMutableArray* groups = [NSMutableArray arrayWithArray:[self.asset.contents arrayGroupedByKey:@"flag"]];
				
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
						title = NSLocalizedString(@"Hangar 1", nil);
					else if (flag >= EVEInventoryFlagCorpSAG2 && flag <= EVEInventoryFlagCorpSAG7) {
						int i = flag - EVEInventoryFlagCorpSAG2 + 2;
						title = [NSString stringWithFormat:NSLocalizedString(@"Hangar %d", nil), i];
					}
					else
						title = NSLocalizedString(@"Unknown hangar", nil);
					NSArray* sortedGroup = [group sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
					if (sortedGroup.count == 1)
						title = [title stringByAppendingString:NSLocalizedString(@" (1 item)", nil)];
					else
						title = [title stringByAppendingFormat:NSLocalizedString(@" (%d items)", nil), sortedGroup.count];
					[assetsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										  title, @"title",
										  [NSNumber numberWithBool:NO], @"collapsed",
										  sortedGroup, @"assets", nil]];
				}
			}
			else if (self.asset.type.groupID == 363) { //Ship Maintenance Array
				NSMutableArray* groups = [NSMutableArray arrayWithArray:[self.asset.contents arrayGroupedByKey:@"type.groupID"]];
				
				[groups sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
					EVEAssetListItem* asset1 = [obj1 objectAtIndex:0];
					EVEAssetListItem* asset2 = [obj2 objectAtIndex:0];
					return [asset1.type.group.groupName compare:asset2.type.group.groupName];
				}];
				
				for (NSArray* group in groups) {
					EVEAssetListItem* item = [group objectAtIndex:0];
					NSString* title = item.type.group.groupName;
					NSArray* sortedGroup = [group sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
					[assetsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										  title, @"title",
										  [NSNumber numberWithBool:NO], @"collapsed",
										  sortedGroup, @"assets", nil]];
				}
			}
			else {
				NSMutableArray* groups = [NSMutableArray arrayWithArray:[self.asset.contents arrayGroupedByKey:@"type.group.categoryID"]];
				
				[groups sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
					EVEAssetListItem* asset1 = [obj1 objectAtIndex:0];
					EVEAssetListItem* asset2 = [obj2 objectAtIndex:0];
					return [asset1.type.group.category.categoryName compare:asset2.type.group.category.categoryName];
				}];
				
				for (NSArray* group in groups) {
					EVEAssetListItem* item = [group objectAtIndex:0];
					NSString* title = item.type.group.category.categoryName;
					NSArray* sortedGroup = [group sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
					[assetsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										  title, @"title",
										  [NSNumber numberWithBool:NO], @"collapsed",
										  sortedGroup, @"assets", nil]];
				}
			}
			
			__block void* weakProcess;
			void (^process)(EVEAssetListItem*) = ^(EVEAssetListItem* item) {
				[filterTmp updateWithValue:item];
				for (EVEAssetListItem* subItem in item.contents)
					((__bridge void (^)(EVEAssetListItem*))weakProcess)(subItem);
			};
			weakProcess = (__bridge void*) process;
			
			float n = self.asset.contents.count;
			float i = 0;
			for (EVEAssetListItem* item in self.asset.contents) {
				weakOperation.progress = i++ / n;
				process(item);
			}
		}];
		
		[operation setCompletionBlockInMainThread:^{
			if (![weakOperation isCancelled]) {
				self.assets = assetsTmp;
				if (self.assets)
					[self reloadAssets];
				self.filter = filterTmp;
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		NSMutableArray* sectionsTmp = [NSMutableArray array];
		if (self.filter.predicate) {
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"AssetContentsViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				__block void* weakSearch;
				void (^search)(NSArray*, NSMutableArray*) = ^(NSArray* contents, NSMutableArray* location) {
					[location addObjectsFromArray:[self.filter applyToValues:contents]];
					for (EVEAssetListItem* item in contents)
						((__bridge void (^)(NSArray*, NSMutableArray*)) weakSearch)(item.contents, location);
				};
				weakSearch = (__bridge void*) search;
				
				NSMutableArray* filteredAssets = [NSMutableArray array];
				float n = self.assets.count;
				float i = 0;
				for (NSDictionary* section in self.assets) {
					weakOperation.progress = i++ / n;
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
						NSArray* sortedGroup = [group sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
						[sectionsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
												title, @"title",
												[NSNumber numberWithBool:NO], @"collapsed",
												sortedGroup, @"assets", nil]];
					}
				}
			}];
			
			[operation setCompletionBlockInMainThread:^(void) {
				if (![weakOperation isCancelled]) {
					self.sections = sectionsTmp;
					[self searchWithSearchString:self.searchBar.text];
					[self.tableView reloadData];
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			self.sections = self.assets;
			[self searchWithSearchString:self.searchBar.text];
		}
	}
	[self.tableView reloadData];
}


- (IBAction) onClose:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (self.sections.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	EUOperation *operation = [EUOperation operationWithIdentifier:@"AssetContentsViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		void (^search)(NSArray*, NSMutableArray*);
		__block void* weakSearch;
		
		search = ^(NSArray* contents, NSMutableArray* values) {
			for (EVEAssetListItem* item in contents) {
				if ([weakOperation isCancelled])
					break;
				if ([item.name rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					[item.type.typeName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					[item.type.group.groupName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					[item.type.group.category.categoryName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					(item.location.itemName && [item.location.itemName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
					[values addObject:item];
				if (self.asset.contents.count > 0)
					((__bridge void (^)(NSArray*, NSMutableArray*)) weakSearch)(item.contents, values);
			}
		};
		weakSearch = (__bridge void*) search;
		
		
		NSMutableArray* values = [[NSMutableArray alloc] init];
		float n = self.sections.count;
		float i = 0;
		for (NSDictionary* section in self.sections) {
			weakOperation.progress = i++ / n / 2;
			search([section valueForKey:@"assets"], values);
		}
		NSMutableArray* values2 =[NSMutableArray arrayWithArray:[self.filter applyToValues:values]];
		
		if (values2.count > 0) {
			NSMutableArray* groups = [NSMutableArray arrayWithArray:[values2 arrayGroupedByKey:@"type.group.categoryID"]];
			[values2 sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];

			[groups sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				EVEAssetListItem* asset1 = [obj1 objectAtIndex:0];
				EVEAssetListItem* asset2 = [obj2 objectAtIndex:0];
				return [asset1.type.group.category.categoryName compare:asset2.type.group.category.categoryName];
			}];
			
			n = groups.count;
			i = 0;
			for (NSArray* group in groups) {
				weakOperation.progress = 0.5 + i++ / n / 2;

				EVEAssetListItem* item = [group objectAtIndex:0];
				NSString* title = item.type.group.category.categoryName;
				NSArray* sortedGroup = [group sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
				[filteredValuesTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
											  title, @"title",
											  [NSNumber numberWithBool:NO], @"collapsed",
											  sortedGroup, @"assets", nil]];
			}
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