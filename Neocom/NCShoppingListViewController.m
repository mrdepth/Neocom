//
//  NCShoppingListViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 31.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingListViewController.h"
#import "NCShoppingItem+Neocom.h"
#import "NCShoppingGroup+Neocom.h"
#import "NCShoppingList.h"
#import "EVEAssetListItem+Neocom.h"
#import "NCStorage.h"
#import "EVECentralAPI.h"
#import "NSString+Neocom.h"
#import "NCLocationsManager.h"
#import "NCPriceManager.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCShoppingItemCell.h"
#import "NCTableViewHeaderView.h"
#import "NCShoppingAssetsViewController.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCAssetsViewControllerDataSection : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* assets;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) id identifier;
@end


@interface NCAssetsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* sections;
@end


@interface NCShoppingListViewControllerSection : NSObject
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, assign) double price;
@end

@interface NCShoppingListViewControllerRow : NSObject
@property (nonatomic, strong) NSMutableArray* items;
@property (nonatomic, strong) NSArray* assets;
@property (nonatomic, assign) CGFloat progress;
@end

@interface NCShoppingListViewControllerAsset : NSObject
@property (nonatomic, strong) EVEAssetListItem* asset;
@property (nonatomic, strong) EVEAssetListItem* parent;
@end

@implementation NCShoppingListViewControllerSection;
@end

@implementation NCShoppingListViewControllerRow;
@end

@implementation NCShoppingListViewControllerAsset;
@end

@interface NCShoppingListViewController()
@property (nonatomic, strong) NSArray* accounts;
@property (nonatomic, strong) NSMutableArray* groupedSections;
@property (nonatomic, strong) NSMutableArray* plainSections;
@property (nonatomic, strong) NCShoppingList* shoppingList;
- (void) updateSelections;
@end

@implementation NCShoppingListViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.shoppingList = [NCShoppingList currentShoppingList];
	
	NCAccount* account = [NCAccount currentAccount];
	if (account) {
		NSArray* accounts = self.accounts;
		if (!accounts)
			self.accounts = @[account];
	}

}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.shoppingList != [NCShoppingList currentShoppingList]) {
		self.shoppingList = [NCShoppingList currentShoppingList];
		[self reloadFromCache];
	}
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	NCStorage* storage = [NCStorage sharedStorage];
	[storage.managedObjectContext performBlock:^{
		if ([storage.managedObjectContext hasChanges])
			[storage.managedObjectContext save:nil];
	}];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
//	[self updateSelections];
}

- (IBAction)onChangeMode:(id)sender {
	[self.tableView reloadData];
//	[self updateSelections];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCShoppingAssetsViewController"]) {
		NCShoppingAssetsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		UIView* cell;
		for (cell = sender; cell && ![cell isKindOfClass:[NCShoppingItemCell class]]; cell = cell.superview);
		NCShoppingListViewControllerRow* row = [(NCShoppingItemCell*) cell object];
		controller.assets = [row.assets valueForKeyPath:@"asset"];
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		UIView* cell;
		for (cell = sender; cell && ![cell isKindOfClass:[NCShoppingItemCell class]]; cell = cell.superview);
		NCShoppingListViewControllerRow* row = [(NCShoppingItemCell*) cell object];

		NCShoppingItem* item = [row.items lastObject];
		controller.type = item.type;
	}
}

- (IBAction)unwindFromShoppingListsManager:(UIStoryboardSegue*) segue {
	self.shoppingList = [NCShoppingList currentShoppingList];
	[self reloadFromCache];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.segmentedControl.selectedSegmentIndex == 0 ? self.groupedSections.count : self.plainSections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCShoppingListViewControllerSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? self.groupedSections[sectionIndex] : self.plainSections[sectionIndex];
	return section.rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCShoppingListViewControllerSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? self.groupedSections[sectionIndex] : self.plainSections[sectionIndex];
	if (section.price > 0)
		return [NSString stringWithFormat:@"%@, %@", section.name, [NSString shortStringWithFloat:section.price unit:@"ISK"]];
	else
		return section.name;
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCShoppingItemCell* cell = (NCShoppingItemCell*) [tableView cellForRowAtIndexPath:indexPath];
	NCShoppingListViewControllerSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? self.groupedSections[indexPath.section] : self.plainSections[indexPath.section];
	NCShoppingListViewControllerRow* row = section.rows[indexPath.row];
	
	cell.finished = !cell.finished;
	for (NCShoppingItem* item in row.items)
		item.finished = cell.finished;
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSMutableArray* sections = self.segmentedControl.selectedSegmentIndex == 0 ? self.groupedSections : self.plainSections;
		NCShoppingListViewControllerSection* section = sections[indexPath.section];
		NCShoppingListViewControllerRow* row = section.rows[indexPath.row];
		
		double price = section.price;
		for (NCShoppingItem* item in row.items)
			price -= item.price.sell.percentile * item.quantity * item.shoppingGroup.quantity;
		section.price = price;
		
		[section.rows removeObjectAtIndex:indexPath.row];
		
		if (section.rows.count == 0) {
			[sections removeObjectAtIndex:indexPath.section];
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
		}
		else {
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			NCTableViewHeaderView* headerView = (NCTableViewHeaderView*) [tableView headerViewForSection:indexPath.section];
			headerView.textLabel.text = [self tableView:tableView titleForHeaderInSection:indexPath.section];
		}
		
		sections = self.segmentedControl.selectedSegmentIndex == 1 ? self.groupedSections : self.plainSections;
		
		NSArray* items = row.items;
		NSInteger sectionIndex = 0;
		NSMutableIndexSet* deleteSections = [NSMutableIndexSet new];
		for (NCShoppingListViewControllerSection* section in sections) {
			NSInteger rowIndex = 0;
			NSMutableIndexSet* deleteRows = [NSMutableIndexSet new];
			for (NCShoppingListViewControllerRow* row in section.rows) {
				[row.items removeObjectsInArray:items];
				if (row.items.count == 0)
					[deleteRows addIndex:rowIndex];
				rowIndex++;
			}
			if (deleteRows.count > 0)
				[section.rows removeObjectsAtIndexes:deleteRows];
			if (section.rows.count == 0)
				[deleteSections addIndex:sectionIndex];
			else {
				double price = 0;
				for (NCShoppingListViewControllerRow* row in section.rows)
					for (NCShoppingItem* item in row.items)
						price += item.price.sell.percentile * item.quantity * item.shoppingGroup.quantity;
				section.price = price;
			}
			sectionIndex++;
		}
		if (deleteSections.count > 0)
			[sections removeObjectsAtIndexes:deleteSections];
		
		NCStorage* storage = [NCStorage sharedStorage];
		[storage.managedObjectContext performBlock:^{
			NSMutableSet* groups = [NSMutableSet new];
			for (NCShoppingItem* item in row.items) {
				[groups addObject:item.shoppingGroup];
				[item.shoppingGroup removeShoppingItemsObject:item];
				[storage.managedObjectContext deleteObject:item];
			}
			for (NCShoppingGroup* group in groups) {
				if (group.shoppingItems.count == 0) {
					[storage.managedObjectContext deleteObject:group];
				}
				else if (group.immutable) {
					group.identifier = [group defaultIdentifier];
				}
			}
//			if ([storage.managedObjectContext hasChanges])
//				[storage.managedObjectContext save:nil];
		}];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	NSMutableArray* ids = [NSMutableArray new];
	for (NCAccount* account in self.accounts)
		[ids addObject:account.uuid];
	[ids sortUsingSelector:@selector(compare:)];
	
	return [NSString stringWithFormat:@"%@.%@", @"NCAssetsViewController", [ids componentsJoinedByString:@","]];
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	NSArray* accounts = self.accounts;
	
	NCAssetsViewControllerData* data = [NCAssetsViewControllerData new];
	__block NSDate* cacheExpireDate = [NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 float totalProgress = 0;
											 float dp = 1.0 / accounts.count;
											 
											 NSMutableArray* sections = [NSMutableArray new];
											 
											 NSMutableDictionary* types = [NSMutableDictionary new];
											 
											 NSMutableArray* controlTowers = [NSMutableArray new];
											 NSMutableArray* freeSpaceItems = [NSMutableArray new];
											 NSMutableArray* topLevelAssets = [NSMutableArray new];
											 NSMutableSet* locationIDs = [NSMutableSet new];
											 
											 
											 for (NCAccount* account in accounts) {
												 BOOL corporate = account.accountType == NCAccountTypeCorporate;
												 NSString* owner = corporate ? account.corporationSheet.corporationName : account.characterInfo.characterName;
												 
												 EVEAssetList* assetsList = [EVEAssetList assetListWithKeyID:account.apiKey.keyID vCode:account.apiKey.vCode cachePolicy:cachePolicy characterID:account.characterID corporate:corporate error:&error progressHandler:^(CGFloat progress, BOOL *stop) {
													 task.progress = totalProgress + progress * dp;
												 }];
												 totalProgress += dp;
												 task.progress = totalProgress;
												 
												 if (!assetsList)
													 continue;
												 cacheExpireDate = [cacheExpireDate laterDate:assetsList.cacheExpireDate];
												 [topLevelAssets addObjectsFromArray:assetsList.assets];
												 
												 NSMutableSet* itemIDs = [NSMutableSet new];
												 
												 
												 __weak __block void (^weakProcess)(EVEAssetListItem*) = nil;
												 
												 void (^process)(EVEAssetListItem*) = ^(EVEAssetListItem* asset) {
													 asset.owner = owner;
													 
													 NCDBInvType* type = types[@(asset.typeID)];
													 if (!type) {
														 type = [NCDBInvType invTypeWithTypeID:asset.typeID];
														 if (type) {
															 types[@(asset.typeID)] = type;
														 }
													 }
													 
													 asset.type = type;
													 
													 if (asset.locationID > 0) {
														 [locationIDs addObject:@(asset.locationID)];
														 if (type.group.groupID == 365) { // ControlTower
															 [controlTowers addObject:asset];
															 [itemIDs addObject:@(asset.itemID)];
														 }
														 else if (type.group.category.categoryID == NCControlTowerGroupID ||
																  type.group.category.categoryID == NCShipCategoryID ||
																  type.group.groupID == NCSecureContainerGroupID) {
															 [freeSpaceItems addObject:asset];
															 [itemIDs addObject:@(asset.itemID)];
														 }
													 }
													 for (EVEAssetListItem* item in asset.contents)
														 weakProcess(item);
												 };
												 weakProcess = process;
												 
												 for (EVEAssetListItem* asset in assetsList.assets)
													 process(asset);
												 
												 if (itemIDs.count > 0 && ((corporate && account.apiKey.apiKeyInfo.key.accessMask & 16777216) ||
																		   (!corporate && account.apiKey.apiKeyInfo.key.accessMask & 134217728))) {
													 
													 EVELocations* eveLocations = nil;
													 NSMutableDictionary* locations = [NSMutableDictionary dictionary];
													 NSArray* allIDs = [[itemIDs allObjects] sortedArrayUsingSelector:@selector(compare:)];
													 
													 int32_t first = 0;
													 int32_t left = (int32_t) itemIDs.count;
													 while (left > 0) {
														 int32_t length = left > 100 ? 100 : left;
														 NSArray* subArray = [allIDs subarrayWithRange:NSMakeRange(first, length)];
														 first += length;
														 left -= length;
														 NSError* error = nil;
														 eveLocations = [EVELocations locationsWithKeyID:account.apiKey.keyID vCode:account.apiKey.vCode cachePolicy:cachePolicy characterID:account.characterID ids:subArray corporate:corporate error:&error progressHandler:nil];
														 for (EVELocationsItem* location in eveLocations.locations)
															 locations[@(location.itemID)] = location;
													 }
													 
													 
													 for (NSArray* array in @[controlTowers, freeSpaceItems])
														 for (EVEAssetListItem* asset in array)
															 asset.location = locations[@(asset.itemID)];
													 
													 for (EVEAssetListItem* controlTower in controlTowers) {
														 EVELocationsItem* controlTowerLocation = controlTower.location;
														 if (controlTower.location){
															 float x0 = controlTowerLocation.x;
															 float y0 = controlTowerLocation.y;
															 float z0 = controlTowerLocation.z;
															 for (EVEAssetListItem* asset in [freeSpaceItems copy]) {
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
																		 [freeSpaceItems removeObject:asset];
																		 [topLevelAssets removeObject:asset];
																	 }
																 }
															 }
														 }
													 }
												 }
											 }
											 
											 if (locationIDs.count > 0) {
												 NSDictionary* locationsNames = [[NCLocationsManager defaultManager] locationsNamesWithIDs:[locationIDs allObjects]];
												 [locationsNames enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NCLocationsManagerItem* item, BOOL *stop) {
													 
													 NSMutableArray* locationAssets = [NSMutableArray new];
													 long long locationID = [key longLongValue];
													 for (EVEAssetListItem* asset in [NSArray arrayWithArray:topLevelAssets]) {
														 if (asset.locationID == locationID) {
															 [locationAssets addObject:asset];
															 [topLevelAssets removeObject:asset];
														 }
													 }
													 [locationAssets sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
													 NCAssetsViewControllerDataSection* section = [NCAssetsViewControllerDataSection new];
													 section.assets = locationAssets;
													 if (item.name)
														 section.title = item.name;
													 else if (item.solarSystem)
														 section.title = item.solarSystem.solarSystemName;
													 else
														 section.title = NSLocalizedString(@"Unknown location", nil);
													 section.identifier = key;
													 [sections addObject:section];
												 }];
											 }
											 
											 if (topLevelAssets.count > 0) {
												 NCAssetsViewControllerDataSection* section = [NCAssetsViewControllerDataSection new];
												 section.assets = topLevelAssets;
												 section.title = NSLocalizedString(@"Unknown location", nil);
												 section.identifier = @(0);
												 [sections addObject:section];
											 }
											 
											 [sections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
											 data.sections = sections;
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:data withCacheDate:[NSDate date] expireDate:cacheExpireDate];
									 }
								 }
							 }];
}

- (void) update {
	NCAssetsViewControllerData* data = self.data;
	NSMutableArray* groupedSections = [NSMutableArray new];
	NSMutableArray* plainSections = [NSMutableArray new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NSMutableDictionary* assets = [NSMutableDictionary new];
											 
											 __weak __block void (^weakProcess)(EVEAssetListItem*) = nil;
											 void (^process)(EVEAssetListItem*) = ^(EVEAssetListItem* item) {
												 NSMutableArray* array = assets[@(item.typeID)];
												 if (!array)
													 assets[@(item.typeID)] = array = [NSMutableArray new];
												 NCShoppingListViewControllerAsset* asset = [NCShoppingListViewControllerAsset new];
												 asset.asset = item;
												 asset.parent = item.parent;
												 [array addObject:asset];
												 
												 for (EVEAssetListItem* subItem in item.contents) {
													 weakProcess(subItem);
												 }
											 };
											 
											 weakProcess = process;

											 for (NCAssetsViewControllerDataSection* section in data.sections) {
												 for (EVEAssetListItem* item in section.assets) {
													 process(item);
												 }
											 }

											 
											 NCStorage* storage = [NCStorage sharedStorage];
											 NSMutableArray* itemsWithoutPrice = [NSMutableArray new];
											 NSMutableDictionary* items = [NSMutableDictionary new];

											 [storage.backgroundManagedObjectContext performBlockAndWait:^{
												 
												 for (NCShoppingGroup* group in self.shoppingList.shoppingGroups) {
													 NCShoppingListViewControllerSection* section = [NCShoppingListViewControllerSection new];
													 section.rows = [NSMutableArray new];
													 
													 for (NCShoppingItem* item in group.shoppingItems) {
														 NCShoppingListViewControllerRow* row = [NCShoppingListViewControllerRow new];
														 row.items = [NSMutableArray arrayWithObject:item];
														 [section.rows addObject:row];
														 row.assets = assets[@(item.typeID)];
														 
														 if (item.price == nil)
															 [itemsWithoutPrice addObject:item];
														 
														 NSMutableArray* array = items[@(item.typeID)];
														 if (!array)
															 items[@(item.typeID)] = array = [NSMutableArray new];
														 [array addObject:item];
													 }
													 if (group.immutable)
														 section.name = [NSString stringWithFormat:NSLocalizedString(@"%@, x%d", nil), group.name, group.quantity];
													 else
														 section.name = group.name;
													 [groupedSections addObject:section];
												 }
											 }];
											 
											 if (itemsWithoutPrice.count > 0) {
												 NCPriceManager* priceManager = [NCPriceManager sharedManager];
												 NSDictionary* prices = [priceManager pricesWithTypes:[itemsWithoutPrice valueForKey:@"typeID"]];
												 for (NCShoppingItem* item in itemsWithoutPrice)
													 item.price = prices[@(item.typeID)];
											 }
											 
											 [storage.backgroundManagedObjectContext performBlockAndWait:^{
												 for (NCShoppingListViewControllerSection* section in groupedSections) {
													 double price = 0;
													 for (NCShoppingListViewControllerRow* row in section.rows) {
														 for (NCShoppingItem* item in row.items)
															 price += item.quantity * item.shoppingGroup.quantity * item.price.sell.percentile;
													 }
													 section.price = price;
												 }
												 
												 NSMutableDictionary* dic = [NSMutableDictionary new];
												 [items enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableArray* array, BOOL *stop) {
													 NCShoppingItem* item = [array lastObject];
													 NCDBInvMarketGroup* marketGroup = nil;
													 for (marketGroup = item.type.marketGroup; marketGroup.parentGroup; marketGroup = marketGroup.parentGroup);
													 NCShoppingListViewControllerSection* section = dic[@(marketGroup.marketGroupID)];
													 if (!section) {
														 section = [NCShoppingListViewControllerSection new];
														 section.rows = [NSMutableArray new];
														 section.name = marketGroup.marketGroupName;
														 section.price = 0;
														 dic[@(marketGroup.marketGroupID)] = section;
													 }
													 NCShoppingListViewControllerRow* row = [NCShoppingListViewControllerRow new];
													 double price = section.price;
													 for (NCShoppingItem* item in array)
														 price += item.quantity * item.shoppingGroup.quantity * item.price.sell.percentile;
													 
													 section.price = price;

													 row.items = array;
													 row.assets = assets[@(item.typeID)];

													 [section.rows addObject:row];
												 }];
												 [plainSections addObjectsFromArray:[dic allValues]];
											 }];
											 
											 for (NCShoppingListViewControllerSection* section in groupedSections)
												 [section.rows sortUsingComparator:^NSComparisonResult(NCShoppingListViewControllerRow* obj1, NCShoppingListViewControllerRow* obj2) {
													 NCShoppingItem* item1 = [obj1.items lastObject];
													 NCShoppingItem* item2 = [obj2.items lastObject];
													 return [item1.type.typeName compare:item2.type.typeName];
												 }];
											 for (NCShoppingListViewControllerSection* section in plainSections)
												 [section.rows sortUsingComparator:^NSComparisonResult(NCShoppingListViewControllerRow* obj1, NCShoppingListViewControllerRow* obj2) {
													 NCShoppingItem* item1 = [obj1.items lastObject];
													 NCShoppingItem* item2 = [obj2.items lastObject];
													 return [item1.type.typeName compare:item2.type.typeName];
												 }];
											 [groupedSections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
											 [plainSections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
											 
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 self.groupedSections = groupedSections;
									 self.plainSections = plainSections;
								 }
								 [super update];
//								 [self updateSelections];
							 }];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}

- (id) identifierForSection:(NSInteger)sectionIndex {
	return nil;
}

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCShoppingItemCell* cell = (NCShoppingItemCell*) tableViewCell;
	
	NCShoppingListViewControllerSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? self.groupedSections[indexPath.section] : self.plainSections[indexPath.section];
	NCShoppingListViewControllerRow* row = section.rows[indexPath.row];

	int32_t quantity = 0;
	for (NCShoppingItem* item in row.items)
		quantity += item.quantity * item.shoppingGroup.quantity;

	NCShoppingItem* item = [row.items lastObject];

	cell.titleLabel.text = item.type.typeName;
	NSMutableString* subtitle = [[NSMutableString alloc] initWithFormat:NSLocalizedString(@"x%d", nil), quantity];

	if (item.price.sell.percentile > 0)
		[subtitle appendFormat:NSLocalizedString(@", %@", nil), [NSString shortStringWithFloat:item.price.sell.percentile * quantity unit:@"ISK"]];
	
	NSInteger available = [[row.assets valueForKeyPath:@"@sum.asset.quantity"] integerValue];
	if (available > 0) {
		[subtitle appendFormat:NSLocalizedString(@", available %@", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:available]];
		cell.widthConstraint.constant = 32;
	}
	else
		cell.widthConstraint.constant = 0;
	
	cell.subtitleLabel.text = subtitle;
	
	cell.iconView.image = item.type.icon ? item.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.object = row;

	BOOL finished = YES;
	for (NCShoppingItem* item in row.items)
		if (!item.finished) {
			finished = NO;
			break;
		}
	cell.finished = finished;
}

#pragma mark - Private

- (void) updateSelections {
	NSArray* sections = self.segmentedControl.selectedSegmentIndex == 0 ? self.groupedSections : self.plainSections;
	NSInteger sectionIndex = 0;
	for (NCShoppingListViewControllerSection* section in sections) {
		NSInteger rowIndex = 0;
		for (NCShoppingListViewControllerRow* row in section.rows) {
			BOOL finished = YES;
			for (NCShoppingItem* item in row.items)
				if (!item.finished) {
					finished = NO;
					break;;
				}
			if (finished)
				[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex] animated:NO scrollPosition:UITableViewScrollPositionNone];
			rowIndex++;
		}
		sectionIndex++;
	}
}

@end
