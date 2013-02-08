//
//  AssetsViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AssetsViewController.h"
#import "EVEOnlineAPI.h"
#import "EVEDBAPI.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "SelectCharacterBarButtonItem.h"
#import "UIAlertView+Error.h"
#import "ItemCellView.h"
#import "ItemViewController.h"
#import "AssetContentsViewController.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface AssetsViewController() {
	NSMutableArray *filteredValues;
	NSMutableArray *assets;
	NSMutableArray *charAssets;
	NSMutableArray *corpAssets;
	EUFilter *charFilter;
	EUFilter *corpFilter;
}
@property (nonatomic, retain) NSArray* accounts;
@property (nonatomic, retain) UIPopoverController* popover;


- (void) reloadAssets;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
- (void) didTapSection:(UITapGestureRecognizer*) recognizer;
- (IBAction)onCombined:(id)sender;
@end

@implementation AssetsViewController
@synthesize assetsTableView;
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
	self.title = NSLocalizedString(@"Assets", nil);
	
	if (!self.accounts) {
		EVEAccount* account = [EVEAccount currentAccount];
		if (account)
			self.accounts = [NSArray arrayWithObject:account];
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		//[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:ownerSegmentControl] autorelease]];
		self.navigationItem.titleView = ownerSegmentControl;
		self.filterPopoverController = [[[UIPopoverController alloc] initWithContentViewController:filterNavigationViewController] autorelease];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
	}
//	else
//		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Combined", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onCombined:)] autorelease];
	
	ownerSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsAssetsOwner];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	[self reloadAssets];
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
		[self.assetsTableView handleShake];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	self.assetsTableView = nil;
	self.ownerSegmentControl = nil;
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	self.popover = nil;
	[assets release];
	[charAssets release];
	[corpAssets release];
	[filteredValues release];
	[charFilter release];
	[corpFilter release];
	assets = charAssets = corpAssets = filteredValues = nil;
	charFilter = corpFilter = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[assetsTableView release];
	[ownerSegmentControl release];
	[searchBar release];
	[filteredValues release];
	[assets release];
	[charAssets release];
	[corpAssets release];
	[filterViewController release];
	[filterNavigationViewController release];
	[filterPopoverController release];
	[charFilter release];
	[corpFilter release];
	[_accounts release];
	[_popover release];
    [super dealloc];
}

- (IBAction) onChangeOwner:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:ownerSegmentControl.selectedSegmentIndex forKey:SettingsAssetsOwner];
	[self reloadAssets];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return filteredValues.count;
	else
		return assets.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	NSDictionary* dic;
	if (self.searchDisplayController.searchResultsTableView == tableView)
		dic = [filteredValues objectAtIndex:section];
	else
		dic = [assets objectAtIndex:section];
	return [[dic valueForKey:@"assets"] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"ItemCellView";
	
    ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	EVEAssetListItem* asset;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		asset = [[[filteredValues objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	else
		asset = [[[assets objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	
	cell.iconImageView.image = [UIImage imageNamed:asset.type.typeSmallImageName];

	if (asset.parent) {
		cell.titleLabel.numberOfLines = 2;
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@\nIn: %@", nil), asset.name, asset.parent.name];
	}
	else {
		cell.titleLabel.numberOfLines = 1;
		cell.titleLabel.text = asset.name;
	}
	cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSDictionary* dic;
	if (tableView == self.searchDisplayController.searchResultsTableView)
		dic = [filteredValues objectAtIndex:section];
	else
		dic = [assets objectAtIndex:section];
	NSInteger count = [[dic valueForKey:@"assets"] count];
	return count == 1 ?
			[NSString stringWithFormat:NSLocalizedString(@"%@ (1 item)", nil), [dic valueForKey:@"title"]] :
			[NSString stringWithFormat:NSLocalizedString(@"%@ (%d items)", nil), [dic valueForKey:@"title"], count];
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	EVEAssetListItem* asset;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		asset = [[[filteredValues objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	else
		asset = [[[assets objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = asset.type;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	EVEAssetListItem* asset;
	
	if (self.searchDisplayController.searchResultsTableView == tableView) {
		asset = [[[filteredValues objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
//		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//			[self.searchDisplayController setActive:NO];
		
	}
	else
		asset = [[[assets objectAtIndex:indexPath.section] valueForKey:@"assets"] objectAtIndex:indexPath.row];
	
	if (asset.contents.count > 0) {
		AssetContentsViewController* controller = [[AssetContentsViewController alloc] initWithNibName:@"AssetContentsViewController" bundle:nil];
		controller.asset = asset;
		controller.corporate = ownerSegmentControl.selectedSegmentIndex == 1;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else {
		ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		
		controller.type = asset.type;
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
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.collapsed = NO;
		view.titleLabel.text = title;
		if (tableView == self.searchDisplayController.searchResultsTableView)
			view.collapsImageView.hidden = YES;
		else
			view.collapsed = [self tableView:tableView sectionIsCollapsed:section];
		return view;
	}
	else
		return nil;
}

#pragma mark - CollapsableTableViewDelegate

- (BOOL) tableView:(UITableView *)tableView sectionIsCollapsed:(NSInteger) section {
	return [[[assets objectAtIndex:section] valueForKey:@"collapsed"] boolValue];
}

- (BOOL) tableView:(UITableView *)tableView canCollapsSection:(NSInteger) section {
	return YES;
}

- (void) tableView:(UITableView *)tableView didCollapsSection:(NSInteger) section {
	[[assets objectAtIndex:section] setValue:@(YES) forKey:@"collapsed"];
}

- (void) tableView:(UITableView *)tableView didExpandSection:(NSInteger) section {
	[[assets objectAtIndex:section] setValue:@(NO) forKey:@"collapsed"];
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
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background3.png"]] autorelease];
	else {
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]] autorelease];
		tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
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
	[self reloadAssets];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - AccountsSelectionViewControllerDelegate

- (void) accountsSelectionViewController:(AccountsSelectionViewController*) controller didSelectAccounts:(NSArray*) accounts {
	self.accounts = accounts;
	[assets release];
	[charAssets release];
	[corpAssets release];
	assets = charAssets = corpAssets = nil;
	[filteredValues release];
	filteredValues = nil;
	[charFilter release];
	[corpFilter release];
	charFilter = corpFilter = nil;
	[self reloadAssets];
}


#pragma mark - Private

- (void) reloadAssets {
	BOOL corporate = (ownerSegmentControl.selectedSegmentIndex == 1);
	NSMutableArray *currentAssets = corporate ? corpAssets : charAssets;
	EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"assetsFilter" ofType:@"plist"]]];
	
	[assets release];
	assets = nil;
	if (!currentAssets) {
		if (corporate) {
			corpAssets = [[NSMutableArray alloc] init];
			currentAssets = corpAssets;
		}
		else {
			charAssets = [[NSMutableArray alloc] init];
			currentAssets = charAssets;
		}
		
		__block EUOperation *operation = [EUOperation operationWithIdentifier:[NSString stringWithFormat:@"AssetsViewController+Load%d", corporate] name:NSLocalizedString(@"Loading Assets", nil)];
		NSMutableArray *assetsTmp = [NSMutableArray array];
		
		[operation addExecutionBlock:^(void) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSError *error = nil;
			NSMutableSet* usedIDs = [NSMutableSet set];
			float n = self.accounts.count;
			float i = 0;
			for (EVEAccount* account in self.accounts) {
				NSInteger characterID = account.characterID;
				if (corporate)
					characterID = -characterID;
				//NSNumber* currentID = corporate ? @(account.corpKeyID) : @(account.charKeyID);
				NSNumber* currentID = @(characterID);
				operation.progress = i / n;
				
				if ([usedIDs containsObject:currentID]) {
					i++;
					continue;
				}
				[usedIDs addObject:currentID];
				
				EVEAssetList *assetsList;
				if (corporate)
					assetsList = [EVEAssetList assetListWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID corporate:corporate error:&error];
				else
					assetsList = [EVEAssetList assetListWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID corporate:corporate error:&error];
				
				if (error) {
					[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
				}
				else {
					NSMutableSet *locationIDs = [NSMutableSet set];
					NSMutableSet *itemIDs = [NSMutableSet set];
					NSMutableDictionary* types = [NSMutableDictionary dictionary];
					NSMutableDictionary* groups = [NSMutableDictionary dictionary];
					NSMutableDictionary* categories = [NSMutableDictionary dictionary];
					
					NSMutableArray* controlTowers = [NSMutableArray array];
					NSMutableArray* structures = [NSMutableArray array];
					NSMutableArray* topLevelAssets = [NSMutableArray arrayWithArray:assetsList.assets];
					
					__block void (^process)(EVEAssetListItem*);
					process = ^(EVEAssetListItem* asset) {
						NSString* typeID = [NSString stringWithFormat:@"%d", asset.typeID];
						EVEDBInvType* type = [types valueForKey:typeID];
						if (!type) {
							type = [EVEDBInvType invTypeWithTypeID:asset.typeID error:nil];
							if (type) {
								NSString* groupID = [NSString stringWithFormat:@"%d", type.groupID];
								EVEDBInvGroup* group = [groups valueForKey:groupID];
								if (!group) {
									group = [EVEDBInvGroup invGroupWithGroupID:type.groupID error:nil];
									if (group) {
										NSString* categoryID = [NSString stringWithFormat:@"%d", group.categoryID];
										EVEDBInvCategory* category = [categories valueForKey:categoryID];
										if (!category) {
											category = [EVEDBInvCategory invCategoryWithCategoryID:group.categoryID error:nil];
											if (category)
												[categories setValue:category forKey:categoryID];
										}
										group.category = category;
										[groups setValue:group forKey:groupID];
									}
								}
								type.group = group;
								[types setValue:type forKey:typeID];
							}
						}
						asset.type = type;
						if (self.accounts.count > 1)
							asset.characterName = account.characterName;
						[filterTmp updateWithValue:asset];
						
						if (asset.locationID > 0) {
							[locationIDs addObject:[NSString stringWithFormat:@"%qi", asset.locationID]];
							if (type.groupID == 365) { // ControlTower
								[controlTowers addObject:asset];
								[itemIDs addObject:[NSString stringWithFormat:@"%qi", asset.itemID]];
							}
							else if (type.group.categoryID == 23) { //Structure
								[structures addObject:asset];
								[itemIDs addObject:[NSString stringWithFormat:@"%qi", asset.itemID]];
							}
							else if (type.group.categoryID == 6) { //Ship
								[structures addObject:asset];
								[itemIDs addObject:[NSString stringWithFormat:@"%qi", asset.itemID]];
							}
							else if (type.groupID == 340) { //Secure Container
								[structures addObject:asset];
								[itemIDs addObject:[NSString stringWithFormat:@"%qi", asset.itemID]];
							}
						}
						
						for (EVEAssetListItem* item in asset.contents)
							process(item);
					};
					operation.progress = (i + 0.5) / n;
					float n1 = assetsList.assets.count;
					float i1 = 0;
					for (EVEAssetListItem* asset in assetsList.assets) {
						operation.progress = (i + 0.5 + i1++ / n1 * 0.5) / n;
						process(asset);
					}
					
					if (itemIDs.count > 0 && ((corporate && account.corpAccessMask & 16777216) || (!corporate && account.charAccessMask & 134217728))) {
						EVELocations* eveLocations = nil;
						NSMutableDictionary* locations = [NSMutableDictionary dictionary];
						NSArray* allIDs = [[itemIDs allObjects] sortedArrayUsingSelector:@selector(compare:)];
						
						NSInteger first = 0;
						NSInteger left = itemIDs.count;
						while (left > 0) {
							int length = left > 100 ? 100 : left;
							NSArray* subArray = [allIDs subarrayWithRange:NSMakeRange(first, length)];
							first += length;
							left -= length;
							if (corporate)
								eveLocations = [EVELocations locationsWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID ids:subArray corporate:corporate error:&error];
							else
								eveLocations = [EVELocations locationsWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID ids:subArray corporate:corporate error:&error];
							for (EVELocationsItem* location in eveLocations.locations)
								[locations setValue:location forKey:[NSString stringWithFormat:@"%qi", location.itemID]];
						}
						
						
						for (NSArray* array in [NSArray arrayWithObjects:controlTowers, structures, nil]) {
							for (EVEAssetListItem* asset in array) {
								EVELocationsItem* location = [locations valueForKey:[NSString stringWithFormat:@"%qi", asset.itemID]];
								if (location) {
									asset.location = location;
									asset.name = location.itemName;
								}
							}
						}
						
						for (EVEAssetListItem* controlTower in controlTowers) {
							EVELocationsItem* controlTowerLocation = controlTower.location;
							if (controlTower.location){
								float x0 = controlTowerLocation.x;
								float y0 = controlTowerLocation.y;
								float z0 = controlTowerLocation.z;
								for (EVEAssetListItem* asset in [NSArray arrayWithArray:structures]) {
									EVELocationsItem* assetLocation = asset.location;
									if (assetLocation && asset.locationID == controlTower.locationID) {
										float x1 = assetLocation.x;
										float y1 = assetLocation.y;
										float z1 = assetLocation.z;
										float dx = fabsf(x0 - x1);
										float dy = fabsf(y0 - y1);
										float dz = fabsf(z0 - z1);
										if (dx < 100000 && dy < 100000 && dz < 100000) {
											[controlTower.contents addObject:asset];
											asset.parent = controlTower;
											asset.locationID = 0;
											[structures removeObject:asset];
											[topLevelAssets removeObject:asset];
										}
									}
								}
							}
						}
					}
					
					if (locationIDs.count > 0) {
						EVECharacterName* locationNames = [EVECharacterName characterNameWithIDs:[locationIDs allObjects] error:nil];
						if (locationNames) {
							for (NSString* key in [locationNames.characters allKeys]) {
								NSMutableArray* locationAssets = [NSMutableArray array];
								long long locationID = [key longLongValue];
								for (EVEAssetListItem* asset in [NSArray arrayWithArray:topLevelAssets]) {
									if (asset.locationID == locationID) {
										[locationAssets addObject:asset];
										[topLevelAssets removeObject:asset];
									}
								}
								[locationAssets sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
								NSString* title = [locationNames.characters valueForKey:key];
								[assetsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
													  title ? title : NSLocalizedString(@"Unknown location", nil), @"title",
													  [NSNumber numberWithBool:YES], @"expanded",
													  locationAssets, @"assets", nil]];
							}
						}
					}
					if (topLevelAssets.count > 0) {
						[assetsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
											  NSLocalizedString(@"Unknown location", nil), @"title",
											  [NSNumber numberWithBool:YES], @"expanded",
											  topLevelAssets, @"assets", nil]];
					}
					[assetsTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
					i++;
				}
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
				[currentAssets addObjectsFromArray:assetsTmp];
				if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate)
					[self reloadAssets];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		EUFilter *filter = corporate ? corpFilter : charFilter;
		NSMutableArray *assetsTmp = [NSMutableArray array];
		if (filter.predicate) {
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"AssetsViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
			[operation addExecutionBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

				__block void (^search)(NSArray*, NSMutableArray*);
				search = ^(NSArray* contents, NSMutableArray* location) {
					[location addObjectsFromArray:[filter applyToValues:contents]];
					for (EVEAssetListItem* item in contents)
						search(item.contents, location);
				};
				float n = currentAssets.count;
				float i = 0;
				for (NSDictionary* section in currentAssets) {
					NSMutableArray* location = [NSMutableArray array];
					
					search([section valueForKey:@"assets"], location);
					if (location.count > 0) {
						[location sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
						[assetsTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
											  [section valueForKey:@"title"], @"title",
											  [NSNumber numberWithBool:YES], @"expanded",
											  location, @"assets", nil]];
					}
					operation.progress = i++ / n;
				}
				[pool release];
			}];
			
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![operation isCancelled]) {
					if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						[assets release];
						assets = [assetsTmp retain];
						[self searchWithSearchString:self.searchBar.text];
						[assetsTableView reloadData];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			assets = [currentAssets retain];
			if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
				[self searchWithSearchString:self.searchBar.text];
			}
		}
	}
	[assetsTableView reloadData];
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	if (!account) {
		self.accounts = nil;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[assets release];
			[charAssets release];
			[corpAssets release];
			assets = charAssets = corpAssets = nil;
			[filteredValues release];
			filteredValues = nil;
			[charFilter release];
			[corpFilter release];
			charFilter = corpFilter = nil;
			[self reloadAssets];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		self.accounts = [NSArray arrayWithObject:account];

		[assets release];
		[charAssets release];
		[corpAssets release];
		assets = charAssets = corpAssets = nil;
		[filteredValues release];
		filteredValues = nil;
		[charFilter release];
		[corpFilter release];
		charFilter = corpFilter = nil;
		[self reloadAssets];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (assets.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];

	BOOL corporate = (ownerSegmentControl.selectedSegmentIndex == 1);
	EUFilter *filter = corporate ? corpFilter : charFilter;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"AssetsViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		__block void (^search)(NSArray*, NSMutableArray*);
		
		search = ^(NSArray* contents, NSMutableArray* values) {
			for (EVEAssetListItem* asset in contents) {
				if ([asset.name rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					[asset.type.typeName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					[asset.type.group.groupName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					[asset.type.group.category.categoryName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
					(asset.location.itemName && [asset.location.itemName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
					[values addObject:asset];
				if (asset.contents.count > 0)
					search(asset.contents, values);
			}
		};

		float n = assets.count;
		float i = 0;
		for (NSDictionary* section in assets) {
			NSMutableArray* values = [[NSMutableArray alloc] init];
			search([section valueForKey:@"assets"], values);
			
			NSMutableArray* values2 =[NSMutableArray arrayWithArray:[filter applyToValues:values]];
			[values release];

			if (values2.count > 0) {
				[values2 sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
				[filteredValuesTmp addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									  [section valueForKey:@"title"], @"title",
									  [NSNumber numberWithBool:YES], @"expanded",
									  values2, @"assets", nil]];
			}
			operation.progress = i++ / n;
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

- (void) didTapSection:(UITapGestureRecognizer*) recognizer {
	NSMutableDictionary* section;
	UITableView* tableView = (UITableView*) recognizer.view.superview;
	NSInteger sectionIndex = recognizer.view.tag;
	if (tableView == self.searchDisplayController.searchResultsTableView)
		section = [filteredValues objectAtIndex:sectionIndex];
	else
		section = [assets objectAtIndex:sectionIndex];
	
	BOOL expanded = ![[section valueForKey:@"expanded"] boolValue];
	[section setValue:[NSNumber numberWithBool:expanded] forKey:@"expanded"];

	UIImage* image = [UIImage imageNamed:expanded ? @"Icons/icon105_04.png" : @"Icons/icon105_05.png"];
	[(UIImageView*) [recognizer.view viewWithTag:-1] setImage:image];
	
	NSMutableArray* indexes = [[NSMutableArray alloc] init];
	int n = [[section valueForKey:@"assets"] count];
	for (int i = 0; i < n; i++)
		[indexes addObject:[NSIndexPath indexPathForRow:i inSection:sectionIndex]];

	if (expanded)
		[tableView insertRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
	else
		[tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
	[indexes release];
}

- (IBAction)onCombined:(id)sender {
	if ([self.popover isPopoverVisible])
		return;
	
	AccountsSelectionViewController* controller = [[AccountsSelectionViewController alloc] initWithNibName:@"AccountsSelectionViewController" bundle:nil];
	controller.selectedAccounts = self.accounts;
	controller.delegate = self;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.popover = [[[UIPopoverController alloc] initWithContentViewController:controller] autorelease];
		[self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

@end