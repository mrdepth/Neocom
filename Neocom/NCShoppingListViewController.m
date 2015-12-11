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
#import "NSString+Neocom.h"
#import "NCLocationsManager.h"
#import "NCPriceManager.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCShoppingItemCell.h"
#import "NCTableViewHeaderView.h"
#import "NCShoppingAssetsViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCShoppingListsManagerViewController.h"
#import "NCAccountsManager.h"

@interface NCAssetsViewControllerDataSection : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* assets;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) id identifier;
@end


@interface NCAssetsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, assign) double balance;
@end



@interface NCShoppingListViewControllerSection : NSObject
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, assign) double price;
@end

@interface NCShoppingListViewControllerItem : NSObject
@property (nonatomic, strong) NCShoppingItem* shoppingItem;
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, assign) double price;
@property (nonatomic, assign) int32_t typeID;
@property (nonatomic, readonly) double cost;
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

@implementation NCShoppingListViewControllerItem

- (double) cost {
	return self.price * self.shoppingItem.quantity * self.shoppingItem.shoppingGroup.quantity;
}

@end

@implementation NCShoppingListViewControllerSection;
@end

@implementation NCShoppingListViewControllerRow;
@end

@implementation NCShoppingListViewControllerAsset;
@end

@interface NCShoppingListViewController()<NCShoppingListsManagerViewControllerDelegate>
@property (nonatomic, strong) NSArray* accounts;
@property (nonatomic, strong) NSMutableArray* groupedSections;
@property (nonatomic, strong) NSMutableArray* plainSections;
@property (nonatomic, strong) NCShoppingList* shoppingList;
- (void) updateSelections;
@end

@implementation NCShoppingListViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.shoppingList = [self.storageManagedObjectContext currentShoppingList];
	
	NCAccount* account = [NCAccount currentAccount];
	if (account) {
		NSArray* accounts = self.accounts;
		if (!accounts)
			self.accounts = @[account];
		else
			[self reload];
	}
	else
		[self reload];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.shoppingList != [self.storageManagedObjectContext currentShoppingList]) {
		self.shoppingList = [self.storageManagedObjectContext currentShoppingList];
		[self reload];
	}
	
	if (self.shoppingList) {
		NSString* name = self.shoppingList.name;
		self.navigationItem.rightBarButtonItem.title = name;
	}
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
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
	[super prepareForSegue:segue sender:sender];
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

		NCShoppingListViewControllerItem* item = [row.items lastObject];
		controller.typeID = [item.type objectID];
	}
	else if ([segue.identifier isEqualToString:@"NCShoppingListsManagerViewController"]) {
		NCShoppingListsManagerViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.delegate = self;
	}
}

- (IBAction)unwindFromShoppingListsManager:(UIStoryboardSegue*) segue {
	if (self.shoppingList != [self.storageManagedObjectContext currentShoppingList]) {
		self.shoppingList = [self.storageManagedObjectContext currentShoppingList];
		[self reload];
	}
	
	if (self.shoppingList) {
		NSString* name = self.shoppingList.name;
		self.navigationItem.rightBarButtonItem.title = name;
	}
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
	for (NCShoppingListViewControllerItem* item in row.items)
		item.shoppingItem.finished = cell.finished;
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
		for (NCShoppingListViewControllerItem* item in row.items)
			price -= item.cost;
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
					for (NCShoppingListViewControllerItem* item in row.items)
						price += item.cost;
				section.price = price;
			}
			sectionIndex++;
		}
		if (deleteSections.count > 0)
			[sections removeObjectsAtIndexes:deleteSections];
		
		NSMutableSet* groups = [NSMutableSet new];
		for (NCShoppingListViewControllerItem* item in row.items) {
			[groups addObject:item.shoppingItem.shoppingGroup];
			[item.shoppingItem.shoppingGroup removeShoppingItemsObject:item.shoppingItem];
			[self.storageManagedObjectContext deleteObject:item.shoppingItem];
		}
		for (NCShoppingGroup* group in groups) {
			if (group.shoppingItems.count == 0) {
				[self.storageManagedObjectContext deleteObject:group];
			}
			else if (group.immutable) {
				group.identifier = [group defaultIdentifier];
			}
		}
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

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	__block NSError* lastError = nil;
	NSArray* accounts = self.accounts;
	if (accounts.count == 0) {
		completionBlock(nil);
		return;
	}
	
	NCAssetsViewControllerData* data = [NCAssetsViewControllerData new];
	
	NSMutableArray* sections = [NSMutableArray new];
	
	NSMutableDictionary* types = [NSMutableDictionary new];
	
	NSMutableArray* controlTowers = [NSMutableArray new];
	NSMutableArray* freeSpaceItems = [NSMutableArray new];
	NSMutableArray* topLevelAssets = [NSMutableArray new];
	NSMutableSet* locationIDs = [NSMutableSet new];
	
	NSMutableDictionary* typeIDs = [NSMutableDictionary new];
	
	dispatch_group_t finishGroup = dispatch_group_create();
	NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
	
	NSProgress* loadingProgress = [NSProgress progressWithTotalUnitCount:accounts.count];
	NSProgress* processingProgress = [NSProgress progressWithTotalUnitCount:2];
	
	for (NCAccount* account in accounts) {
		dispatch_group_enter(finishGroup);
		
		[account.managedObjectContext performBlock:^{
			EVEAPIKeyInfoKey* apiKeyInfo = account.apiKey.apiKeyInfo.key;
			EVEAPIKey* apiKey = account.eveAPIKey;
			BOOL corporate = account.accountType == NCAccountTypeCorporate;
			
			void (^loadAssets)(NSString* owner) = ^(NSString* owner) {
				EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:apiKey cachePolicy:cachePolicy];
				[api assetListWithCompletionBlock:^(EVEAssetList *result, NSError *error) {
					lastError = error;
					[databaseManagedObjectContext performBlock:^{
						[topLevelAssets addObjectsFromArray:result.assets];
						
						NSMutableSet* itemIDs = [NSMutableSet new];
						
						__weak __block void (^weakProcess)(EVEAssetListItem*) = nil;
						
						void (^process)(EVEAssetListItem*) = ^(EVEAssetListItem* asset) {
							asset.owner = owner;
							
							NCDBInvType* type = types[@(asset.typeID)];
							if (!type) {
								type = [databaseManagedObjectContext invTypeWithTypeID:asset.typeID];
								if (type) {
									types[@(asset.typeID)] = type;
								}
							}
							
							asset.typeName = type.typeName;
							
							if (type.marketGroup)
								typeIDs[@(asset.typeID)] = @([typeIDs[@(asset.typeID)] longLongValue] + asset.quantity);
							
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
						
						for (EVEAssetListItem* asset in result.assets)
							process(asset);
						
						if (itemIDs.count > 0 && ((corporate && apiKeyInfo.accessMask & 16777216) ||
												  (!corporate && apiKeyInfo.accessMask & 134217728))) {
							
							NSMutableDictionary* locations = [NSMutableDictionary dictionary];
							NSArray* allIDs = [[itemIDs allObjects] sortedArrayUsingSelector:@selector(compare:)];
							
							[api locationsWithIDs:allIDs completionBlock:^(EVELocations *result, NSError *error) {
								[databaseManagedObjectContext performBlock:^{
									for (EVELocationsItem* location in result.locations)
										locations[@(location.itemID)] = location;
									
									for (NSArray* array in @[controlTowers, freeSpaceItems])
										for (EVEAssetListItem* asset in array)
											asset.location = locations[@(asset.itemID)];
									
									for (EVEAssetListItem* controlTower in controlTowers) {
										EVELocationsItem* controlTowerLocation = controlTower.location;
										NSMutableArray* contents = [controlTower.contents mutableCopy] ?: [NSMutableArray new];
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
														[contents addObject:asset];
														asset.parent = controlTower;
														asset.locationID = 0;
														[freeSpaceItems removeObject:asset];
														[topLevelAssets removeObject:asset];
													}
												}
											}
										}
										controlTower.contents = contents;
									}
									dispatch_group_leave(finishGroup);
									@synchronized(loadingProgress) {
										loadingProgress.completedUnitCount++;
									}
								}];
							} progressBlock:nil];
						}
						else {
							dispatch_group_leave(finishGroup);
							@synchronized(loadingProgress) {
								loadingProgress.completedUnitCount++;
							}
						}
					}];
				} progressBlock:nil];
			};
			
			if (corporate)
				[account loadCorporationSheetWithCompletionBlock:^(EVECorporationSheet *corporationSheet, NSError *error) {
					loadAssets(corporationSheet.corporationName);
				}];
			else
				[account loadCharacterInfoWithCompletionBlock:^(EVECharacterInfo *characterInfo, NSError *error) {
					loadAssets(characterInfo.characterName);
				}];
		}];
	}
	
	dispatch_group_notify(finishGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		@autoreleasepool {
			dispatch_group_t finishGroup = dispatch_group_create();
			
			if (locationIDs.count > 0) {
				dispatch_group_enter(finishGroup);
				[[NCLocationsManager defaultManager] requestLocationsNamesWithIDs:[locationIDs allObjects] completionBlock:^(NSDictionary *locationsNames) {
					[databaseManagedObjectContext performBlock:^{
						[locationsNames enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NCLocationsManagerItem* item, BOOL *stop) {
							
							NSMutableArray* locationAssets = [NSMutableArray new];
							long long locationID = [key longLongValue];
							for (EVEAssetListItem* asset in [NSArray arrayWithArray:topLevelAssets]) {
								if (asset.locationID == locationID) {
									[locationAssets addObject:asset];
									[topLevelAssets removeObject:asset];
								}
							}
							[locationAssets sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
							NCAssetsViewControllerDataSection* section = [NCAssetsViewControllerDataSection new];
							section.assets = locationAssets;
							if (item.name)
								section.title = item.name;
							else if (item.solarSystemID)
								section.title = [[databaseManagedObjectContext mapSolarSystemWithSolarSystemID:item.solarSystemID] solarSystemName];
							else
								section.title = NSLocalizedString(@"Unknown location", nil);
							section.identifier = key;
							[sections addObject:section];
						}];
						dispatch_group_leave(finishGroup);
					}];
				}];
			}
			
			dispatch_group_notify(finishGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				@autoreleasepool {
					processingProgress.completedUnitCount++;
					if (topLevelAssets.count > 0) {
						NCAssetsViewControllerDataSection* section = [NCAssetsViewControllerDataSection new];
						section.assets = topLevelAssets;
						section.title = NSLocalizedString(@"Unknown location", nil);
						section.identifier = @(0);
						[sections addObject:section];
					}
					
					[[NCPriceManager sharedManager] requestPricesWithTypes:[typeIDs allKeys]
														   completionBlock:^(NSDictionary *prices) {
															   __block double balance = 0;
															   [typeIDs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
																   double price = [prices[key] doubleValue];
																   balance += price * [obj longLongValue];
															   }];
															   [sections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
															   data.sections = sections;
															   data.balance = balance;
															   dispatch_async(dispatch_get_main_queue(), ^{
																   [self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
																   completionBlock(lastError);
																   processingProgress.completedUnitCount++;
															   });
														   }];
				}
			});
		}
	});
}

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {

	NCAssetsViewControllerData* data = cacheData;
	
	dispatch_group_t finishDispatchGroup = dispatch_group_create();
	
	NSMutableArray* groupedSections = [NSMutableArray new];
	NSMutableArray* plainSections = [NSMutableArray new];
	
	NSMutableDictionary* items = [NSMutableDictionary new];
	
	for (NCShoppingGroup* group in self.shoppingList.shoppingGroups) {
		NCShoppingListViewControllerSection* section = [NCShoppingListViewControllerSection new];
		section.rows = [NSMutableArray new];
		
		for (NCShoppingItem* shoppingItem in group.shoppingItems) {
			NCShoppingListViewControllerRow* row = [NCShoppingListViewControllerRow new];
			NCShoppingListViewControllerItem* item = [NCShoppingListViewControllerItem new];
			item.shoppingItem = shoppingItem;
			item.type = [self.databaseManagedObjectContext invTypeWithTypeID:shoppingItem.typeID];
			item.typeID = shoppingItem.typeID;
			
			row.items = [NSMutableArray arrayWithObject:item];
			[section.rows addObject:row];
			
			NSMutableArray* array = items[@(item.shoppingItem.typeID)];
			if (!array)
				items[@(item.shoppingItem.typeID)] = array = [NSMutableArray new];
			[array addObject:item];
		}
		if (group.immutable)
			section.name = [NSString stringWithFormat:NSLocalizedString(@"%@, x%d", nil), group.name, group.quantity];
		else
			section.name = group.name;
		[groupedSections addObject:section];
	}
	
	NSMutableDictionary* assets = [NSMutableDictionary new];
	
	dispatch_group_async(finishDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		@autoreleasepool {
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
		}
	});
	
	
	dispatch_group_enter(finishDispatchGroup);
	NCPriceManager* priceManager = [NCPriceManager sharedManager];
	[priceManager requestPricesWithTypes:[items allKeys] completionBlock:^(NSDictionary *prices) {
		dispatch_group_async(finishDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			[items enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSArray*  _Nonnull obj, BOOL * _Nonnull stop) {
				for (NCShoppingListViewControllerItem* item in obj)
					item.price = [prices[@(item.typeID)] doubleValue];
			}];
		});
							 

		dispatch_group_leave(finishDispatchGroup);
	}];
	
	dispatch_group_notify(finishDispatchGroup, dispatch_get_main_queue(), ^{
		for (NCShoppingListViewControllerSection* section in groupedSections) {
			double price = 0;
			for (NCShoppingListViewControllerRow* row in section.rows) {
				for (NCShoppingListViewControllerItem* item in row.items)
					price += item.cost;
			}
			section.price = price;
		}

		NSMutableDictionary* dic = [NSMutableDictionary new];
		[items enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableArray* array, BOOL *stop) {
			NCShoppingListViewControllerItem* item = [array lastObject];
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
			for (NCShoppingListViewControllerItem* item in array)
				price += item.cost;
			
			section.price = price;
			
			row.items = array;
			row.assets = assets[@(item.shoppingItem.typeID)];
			
			[section.rows addObject:row];
		}];
		[plainSections addObjectsFromArray:[dic allValues]];
		
		for (NCShoppingListViewControllerSection* section in groupedSections)
			[section.rows sortUsingComparator:^NSComparisonResult(NCShoppingListViewControllerRow* obj1, NCShoppingListViewControllerRow* obj2) {
				NCShoppingListViewControllerItem* item1 = [obj1.items lastObject];
				NCShoppingListViewControllerItem* item2 = [obj2.items lastObject];
				return [item1.type.typeName compare:item2.type.typeName];
			}];
		for (NCShoppingListViewControllerSection* section in plainSections)
			[section.rows sortUsingComparator:^NSComparisonResult(NCShoppingListViewControllerRow* obj1, NCShoppingListViewControllerRow* obj2) {
				NCShoppingListViewControllerItem* item1 = [obj1.items lastObject];
				NCShoppingListViewControllerItem* item2 = [obj2.items lastObject];
				return [item1.type.typeName compare:item2.type.typeName];
			}];
		[groupedSections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
		[plainSections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
		
		
		self.groupedSections = groupedSections;
		self.plainSections = plainSections;
		
		completionBlock();

	});
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
	for (NCShoppingListViewControllerItem* item in row.items)
		quantity += item.shoppingItem.quantity * item.shoppingItem.shoppingGroup.quantity;

	NCShoppingListViewControllerItem* item = [row.items lastObject];

	cell.titleLabel.text = item.type.typeName;
	NSMutableString* subtitle = [[NSMutableString alloc] initWithFormat:NSLocalizedString(@"x%d", nil), quantity];

	if (item.price > 0)
		[subtitle appendFormat:NSLocalizedString(@", %@", nil), [NSString shortStringWithFloat:item.price * quantity unit:@"ISK"]];
	
	NSInteger available = [[row.assets valueForKeyPath:@"@sum.asset.quantity"] integerValue];
	if (available > 0) {
		[subtitle appendFormat:NSLocalizedString(@", available %@", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:available]];
		cell.widthConstraint.constant = 32;
	}
	else
		cell.widthConstraint.constant = 0;
	
	cell.subtitleLabel.text = subtitle;
	
	cell.iconView.image = item.type.icon ? item.type.icon.image.image : [[[self.databaseManagedObjectContext defaultTypeIcon] image] image];
	cell.object = row;

	BOOL finished = YES;
	for (NCShoppingListViewControllerItem* item in row.items)
		if (!item.shoppingItem.finished) {
			finished = NO;
			break;
		}
	cell.finished = finished;
}

#pragma mark - NCShoppingListsManagerViewControllerDelegate

- (void) shoppingListsManagerViewController:(NCShoppingListsManagerViewController*) controller didSelectShoppingList:(NCShoppingList*) shoppingList {
	self.shoppingList = [self.databaseManagedObjectContext currentShoppingList];
	[self reload];
	NSString* name = self.shoppingList.name;
	self.navigationItem.rightBarButtonItem.title = name;
}


#pragma mark - Private

- (void) updateSelections {
	NSArray* sections = self.segmentedControl.selectedSegmentIndex == 0 ? self.groupedSections : self.plainSections;
	NSInteger sectionIndex = 0;
	for (NCShoppingListViewControllerSection* section in sections) {
		NSInteger rowIndex = 0;
		for (NCShoppingListViewControllerRow* row in section.rows) {
			BOOL finished = YES;
			for (NCShoppingListViewControllerItem* item in row.items)
				if (!item.shoppingItem.finished) {
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

- (void) setAccounts:(NSArray *)accounts {
	_accounts = accounts;
	
	[[[NCAccountsManager sharedManager] storageManagedObjectContext] performBlock:^{
		NSMutableArray* ids = [NSMutableArray new];
	 for (NCAccount* account in accounts)
		 [ids addObject:account.uuid];
	 [ids sortUsingSelector:@selector(compare:)];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.cacheRecordID = [NSString stringWithFormat:@"%@.%@", @"NCAssetsViewController", [ids componentsJoinedByString:@","]];
		});
	}];
	
}

@end
