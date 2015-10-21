//
//  NCAssetsViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAssetsViewController.h"
#import "EVEAssetListItem+Neocom.h"
#import "NCTableViewCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCAssetsContainerViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCLocationsManager.h"
#import "NCAssetsAccountsViewController.h"
#import "NCStoryboardPopoverSegue.h"
#import "NCPriceManager.h"
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

@implementation NCAssetsViewControllerDataSection

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.assets = [aDecoder decodeObjectForKey:@"assets"];
		self.title = [aDecoder decodeObjectForKey:@"title"];
		self.identifier = [aDecoder decodeObjectForKey:@"identifier"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.assets)
		[aCoder encodeObject:self.assets forKey:@"assets"];
	if (self.title)
		[aCoder encodeObject:self.title forKey:@"title"];
	if (self.identifier)
		[aCoder encodeObject:self.identifier forKey:@"identifier"];
}

@end

@interface NCAssetsViewController()<NCAssetsAccountsViewControllerDelegate>
@property (nonatomic, strong) NCAssetsViewControllerData* searchResults;
@end

@implementation NCAssetsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.sections = [aDecoder decodeObjectForKey:@"sections"];
		NSDictionary* assetsDetails = [aDecoder decodeObjectForKey:@"assetsDetails"];

//		NSMutableDictionary* types = [NSMutableDictionary new];

		__weak __block void (^weakProcess)(EVEAssetListItem*);
		void (^process)(EVEAssetListItem*) = ^(EVEAssetListItem* asset) {
/*			NCDBInvType* type = types[@(asset.typeID)];
			if (!type) {
				type = [NCDBInvType invTypeWithTypeID:asset.typeID];
				if (type) {
					types[@(asset.typeID)] = type;
				}
			}
			asset.type = type;*/
			
			NSDictionary* details = assetsDetails[@(asset.itemID)];
			asset.owner = details[@"owner"];
			asset.title = details[@"title"];
			asset.location = details[@"location"];
			for (EVEAssetListItem* item in asset.contents)
				weakProcess(item);
		};
		weakProcess = process;
		
		for (NCAssetsViewControllerDataSection* section in self.sections)
			for (EVEAssetListItem* asset in section.assets)
				process(asset);
		self.balance = [aDecoder decodeDoubleForKey:@"balance"];
		
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.sections) {
		[aCoder encodeObject:self.sections forKey:@"sections"];
		
		NSMutableDictionary* assetsDetails = [NSMutableDictionary new];
		__weak __block void (^weakProcess)(EVEAssetListItem*);
		void (^process)(EVEAssetListItem*) = ^(EVEAssetListItem* asset) {
			NSMutableDictionary* details = [NSMutableDictionary new];
			NSString* owner = asset.owner;
			NSString* title = asset.title;
			EVELocationsItem* location = asset.location;
			if (owner)
				details[@"owner"] = owner;
			if (title)
				details[@"title"] = title;
			if (location)
				details[@"location"] = location;
			assetsDetails[@(asset.itemID)] = details;
			for (EVEAssetListItem* item in asset.contents)
				weakProcess(item);
		};
		weakProcess = process;
		
		for (NCAssetsViewControllerDataSection* section in self.sections)
			for (EVEAssetListItem* asset in section.assets)
				process(asset);
		[aCoder encodeObject:assetsDetails forKey:@"assetsDetails"];
		[aCoder encodeDouble:self.balance forKey:@"balance"];
	}
	
}

@end

@interface NCAssetsViewController ()
@property (nonatomic, strong) NSArray* accounts;
@property (nonatomic, strong) NSSet* typeIDs;
@property (nonatomic, strong) NSMutableDictionary* types;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@end

@implementation NCAssetsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        if (!self.searchContentsController) {
            self.searchController = [[UISearchController alloc] initWithSearchResultsController:[self.storyboard instantiateViewControllerWithIdentifier:@"NCAssetsViewController"]];
        }
        else {
            self.tableView.tableHeaderView = nil;
            return;
        }
    }


	self.types = [NSMutableDictionary new];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];

	NCAccount* account = [NCAccount currentAccount];
	if (account) {
		NSArray* accounts = self.accounts;
		if (!accounts)
			self.accounts = @[account];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isKindOfClass:[NCStoryboardPopoverSegue class]]) {
		NCStoryboardPopoverSegue* popoverSegue = (NCStoryboardPopoverSegue*) segue;
		if ([sender isKindOfClass:[UIBarButtonItem class]])
			popoverSegue.anchorBarButtonItem = sender;
		else if ([sender isKindOfClass:[UIView class]])
			popoverSegue.anchorView = sender;
		else
			popoverSegue.anchorBarButtonItem = self.navigationItem.rightBarButtonItem;
	}
	
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		EVEAssetListItem* asset = [sender object];
		controller.typeID = [[self.databaseManagedObjectContext invTypeWithTypeID:asset.typeID] objectID];
	}
	else if ([segue.identifier isEqualToString:@"NCAssetsContainerViewController"]) {
		NCAssetsContainerViewController* destinationViewController = segue.destinationViewController;
		EVEAssetListItem* asset = [sender object];
		destinationViewController.asset = asset;
	}
	else if ([segue.identifier isEqualToString:@"NCAssetsAccountsViewController"]) {
		NCAssetsAccountsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.selectedAccounts = [self.accounts valueForKey:@"objectID"];
		controller.delegate = self;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCAssetsViewControllerData* data = tableView == self.tableView && !self.searchContentsController ? self.cacheData : self.searchResults;
	return data.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCAssetsViewControllerData* data = tableView == self.tableView && !self.searchContentsController ? self.cacheData : self.searchResults;
	return [[data.sections[section] assets] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCAssetsViewControllerData* data = tableView == self.tableView && !self.searchContentsController ? self.cacheData : self.searchResults;
	NCAssetsViewControllerDataSection* section = data.sections[sectionIndex];
	return [NSString stringWithFormat:@"%@ (%@)", section.title, [NSNumberFormatter neocomLocalizedStringFromInteger:section.assets.count]];
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	NCAssetsViewControllerData* data = tableView == self.tableView && !self.searchContentsController ? self.cacheData : self.searchResults;
	NCAssetsViewControllerDataSection* section = data.sections[indexPath.section];
	EVEAssetListItem* asset = section.assets[indexPath.row];
	if (asset.contents.count == 0)
		[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:cell];
	else
		[self performSegueWithIdentifier:@"NCAssetsContainerViewController" sender:cell];
}

#pragma mark - NCTableViewController

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCAssetsViewControllerData* data = cacheData;
	if (data.balance > 0)
		self.balanceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(data.balance)]];
	else
		self.balanceLabel.text = nil;
	
	NSMutableSet* typeIDs = [NSMutableSet new];
	__weak __block void (^weakSearch)(EVEAssetListItem*);
	void (^search)(EVEAssetListItem*) = ^(EVEAssetListItem* asset) {
		[typeIDs addObject:@(asset.typeID)];
		for (EVEAssetListItem* item in asset.contents)
			weakSearch(item);
	};
	weakSearch = search;
	
	for (NCAssetsViewControllerDataSection* section in data.sections) {
		for (EVEAssetListItem* asset in section.assets) {
			search(asset);
		}
	}
	self.typeIDs = typeIDs;
	
	self.backgrountText = data.sections.count > 0 ? nil : NSLocalizedString(@"No Results", nil);

	completionBlock();
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

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	NCAccount* account = [NCAccount currentAccount];
	
	if (account)
		self.accounts = @[account];
	else
		self.accounts = nil;

	
	if ([self isViewLoaded])
		[self reload];
}

- (void) searchWithSearchString:(NSString*) searchString completionBlock:(void (^)())completionBlock {
	NCAssetsViewControllerData* searchResults = [NCAssetsViewControllerData new];
	NCAssetsViewControllerData* data = self.cacheData;
	
	NSSet* typeIDs = self.typeIDs;
	if (searchString.length >= 2 && typeIDs.count > 0) {
		
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		[databaseManagedObjectContext performBlock:^{
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.predicate = [NSPredicate predicateWithFormat:@"typeID IN %@ AND (typeName CONTAINS[C] %@ OR group.groupName CONTAINS[C] %@ OR group.category.categoryName CONTAINS[C] %@)", typeIDs, searchString, searchString, searchString];
			request.resultType = NSDictionaryResultType;
			request.propertiesToFetch = @[[[NSEntityDescription entityForName:@"InvType" inManagedObjectContext:databaseManagedObjectContext] propertiesByName][@"typeID"]];
			NSArray* filteredTypeIDs = [[databaseManagedObjectContext executeFetchRequest:request error:nil] valueForKey:@"typeID"];
			
			__weak __block void (^weakSearch)(EVEAssetListItem*, NSMutableArray*);
			void (^search)(EVEAssetListItem*, NSMutableArray*) = ^(EVEAssetListItem* asset, NSMutableArray* sectionAssets) {
				if ([filteredTypeIDs containsObject:@(asset.typeID)]) {
					[sectionAssets addObject:asset];
				}
				for (EVEAssetListItem* item in asset.contents) {
					weakSearch(item, sectionAssets);
				}
			};
			weakSearch = search;
			
			NSMutableArray* sections = [NSMutableArray new];
			for (NCAssetsViewControllerDataSection* section in data.sections) {
				NSMutableArray* sectionAssets = [NSMutableArray new];
				if (section.title && [section.title rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
					[sectionAssets addObjectsFromArray:section.assets];
				}
				else {
					for (EVEAssetListItem* asset in section.assets) {
						search(asset, sectionAssets);
					}
				}
				if (sectionAssets.count > 0) {
					NCAssetsViewControllerDataSection* searchSection = [NCAssetsViewControllerDataSection new];
					searchSection.assets = sectionAssets;
					searchSection.title = section.title;
					[sections addObject:searchSection];
				}
			}
			searchResults.sections = sections;
			
			self.searchResults = searchResults;
			if (self.searchController) {
				NCAssetsViewController* searchResultsController = (NCAssetsViewController*) self.searchController.searchResultsController;
			 searchResultsController.searchResults = self.searchResults;
			}
			completionBlock();
		}];
	}
	else {
		self.searchResults = nil;
		if (self.searchController) {
			NCAssetsViewController* searchResultsController = (NCAssetsViewController*) self.searchController.searchResultsController;
			searchResultsController.searchResults = self.searchResults;
		}
		completionBlock();
	}
}

- (id) identifierForSection:(NSInteger)sectionIndex {
	NCAssetsViewControllerData* data = self.cacheData;
	NCAssetsViewControllerDataSection* section = data.sections[sectionIndex];
	return section.identifier;
}

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCAssetsViewControllerData* data = tableView == self.tableView && !self.searchContentsController ? self.cacheData : self.searchResults;
	NCAssetsViewControllerDataSection* section = data.sections[indexPath.section];
	EVEAssetListItem* asset = section.assets[indexPath.row];
	
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	NCDBInvType* type = self.types[@(asset.typeID)];
	if (!type) {
		type = [self.databaseManagedObjectContext invTypeWithTypeID:asset.typeID];
		if (type)
			self.types[@(asset.typeID)] = type;
	}
	cell.iconView.image = type.icon ? type.icon.image.image : self.defaultTypeIcon.image.image;
	
	cell.titleLabel.text = asset.title;
	cell.object = asset;
	
	if (self.accounts.count > 1)
		cell.subtitleLabel.text = asset.owner;
	else
		cell.subtitleLabel.text = nil;
}

#pragma mark - NCAssetsAccountsViewControllerDelegate

- (void) assetsAccountsViewController:(NCAssetsAccountsViewController *)controller didSelectAccounts:(NSArray *)accounts {
	NSManagedObjectContext* storageManagedObjectContext = [[NCAccountsManager sharedManager] storageManagedObjectContext];
	[storageManagedObjectContext performBlock:^{
		NSMutableArray* objects = [NSMutableArray new];
		for (NSManagedObjectID* objectID in accounts) {
			NCAccount* account = [storageManagedObjectContext existingObjectWithID:objectID error:nil];
			[objects addObject:account];
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			self.accounts = objects;
		});
	}];
}

#pragma mark - Private

- (void) setAccounts:(NSArray *)accounts {
	_accounts = accounts;
	if (accounts.count == 1) {
		NCAccount* account = self.accounts[0];
		[account.managedObjectContext performBlock:^{
			if (account.accountType == NCAccountTypeCorporate) {
				[account loadCorporationSheetWithCompletionBlock:^(EVECorporationSheet *corporationSheet, NSError *error) {
					dispatch_async(dispatch_get_main_queue(), ^{
						self.navigationItem.rightBarButtonItem.title = corporationSheet.corporationName ?: NSLocalizedString(@"Unknown account", nil);
					});
				}];
			}
			else {
				[account loadCharacterInfoWithCompletionBlock:^(EVECharacterInfo *characterInfo, NSError *error) {
					dispatch_async(dispatch_get_main_queue(), ^{
						self.navigationItem.rightBarButtonItem.title = characterInfo.characterName ?: NSLocalizedString(@"Unknown account", nil);
					});
				}];
			}
		}];
	}
	else if (accounts.count > 1)
		self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:NSLocalizedString(@"%ld Accounts", nil), (long) accounts.count];
	else
		self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Accounts", nil);
	
	[[[NCAccountsManager sharedManager] storageManagedObjectContext] performBlock:^{
		NSMutableArray* ids = [NSMutableArray new];
	 for (NCAccount* account in accounts)
		 [ids addObject:account.uuid];
	 [ids sortUsingSelector:@selector(compare:)];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.cacheRecordID = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), [ids componentsJoinedByString:@","]];
		});
	}];

}

@end
