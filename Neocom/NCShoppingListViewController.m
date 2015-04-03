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
@property (nonatomic, strong) NSArray* items;
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
@property (nonatomic, strong) NSArray* groupedSections;
@property (nonatomic, strong) NSArray* plainSections;
@property (nonatomic, strong) NCShoppingList* shoppingList;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.groupedSections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCShoppingListViewControllerSection* section = self.groupedSections[sectionIndex];
	return section.rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCShoppingListViewControllerSection* section = self.groupedSections[sectionIndex];
	if (section.price > 0)
		return [NSString stringWithFormat:@"%@, %@", section.name, [NSString shortStringWithFloat:section.price unit:@"ISK"]];
	else
		return section.name;
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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

											 [storage.backgroundManagedObjectContext performBlockAndWait:^{
												 
												 for (NCShoppingGroup* group in self.shoppingList.shoppingGroups) {
													 NCShoppingListViewControllerSection* section = [NCShoppingListViewControllerSection new];
													 section.rows = [NSMutableArray new];
													 
													 for (NCShoppingItem* item in group.shoppingItems) {
														 NCShoppingListViewControllerRow* row = [NCShoppingListViewControllerRow new];
														 row.items = @[item];
														 [section.rows addObject:row];
														 row.assets = assets[@(item.typeID)];
														 
														 if (item.price == nil)
															 [itemsWithoutPrice addObject:item];
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
															 price += item.quantity * item.price.sell.percentile;
													 }
													 section.price = price;
												 }
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 self.groupedSections = groupedSections;
								 }
								 [super update];
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
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	
	NCShoppingListViewControllerSection* section = self.groupedSections[indexPath.section];
	NCShoppingListViewControllerRow* row = section.rows[indexPath.row];
	NCShoppingItem* item = [row.items lastObject];
	
	cell.titleLabel.text = item.type.typeName;
	NSMutableString* subtitle = [[NSMutableString alloc] initWithFormat:NSLocalizedString(@"x%d", nil), item.quantity];

	if (item.price)
		[subtitle appendFormat:NSLocalizedString(@", %@", nil), [NSString shortStringWithFloat:item.price.sell.percentile * item.quantity unit:@"ISK"]];
	
	NSInteger available = [[row.assets valueForKeyPath:@"@sum.asset.quantity"] integerValue];
	if (available > 0)
		[subtitle appendFormat:NSLocalizedString(@", available %@", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:available]];
	
	cell.subtitleLabel.text = subtitle;
	
	cell.iconView.image = item.type.icon ? item.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.object = item.type;

}

@end
