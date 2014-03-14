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

@interface NCAssetsViewControllerDataSection : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* assets;
@property (nonatomic, strong) NSString* title;
@end


@interface NCAssetsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* sections;
@end

@implementation NCAssetsViewControllerDataSection

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.assets = [aDecoder decodeObjectForKey:@"assets"];
		self.title = [aDecoder decodeObjectForKey:@"title"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.assets)
		[aCoder encodeObject:self.assets forKey:@"assets"];
	if (self.title)
		[aCoder encodeObject:self.title forKey:@"title"];
}

@end

@interface NCAssetsViewController()
@property (nonatomic, strong) NCAssetsViewControllerData* searchResults;
@end

@implementation NCAssetsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.sections = [aDecoder decodeObjectForKey:@"sections"];
		NSDictionary* assetsDetails = [aDecoder decodeObjectForKey:@"assetsDetails"];

		NSMutableDictionary* types = [NSMutableDictionary new];
		NSMutableDictionary* groups = [NSMutableDictionary new];
		NSMutableDictionary* categories = [NSMutableDictionary new];

		__weak __block void (^weakProcess)(EVEAssetListItem*);
		void (^process)(EVEAssetListItem*) = ^(EVEAssetListItem* asset) {
			EVEDBInvType* type = types[@(asset.typeID)];
			if (!type) {
				type = [EVEDBInvType invTypeWithTypeID:asset.typeID error:nil];
				if (type) {
					types[@(asset.typeID)] = type;
					EVEDBInvGroup* group = groups[@(type.groupID)];
					if (!group) {
						group = type.group;
						if (group) {
							groups[@(type.groupID)] = group;
							EVEDBInvCategory* category = categories[@(group.categoryID)];
							if (!category) {
								category = group.category;
								if (category) {
									categories[@(group.categoryID)] = category;
								}
							}
							else
								group.category = category;
						}
					}
					else
						type.group = group;
				}
			}
			asset.type = type;
			
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
	}
	
}

@end

@interface NCAssetsViewController ()
@property (nonatomic, strong) NSArray* accounts;
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
	NCAccount* account = [NCAccount currentAccount];
	if (account) {
		NSArray* accounts = self.accounts;
		if (!accounts)
			self.accounts = @[account];
	}

	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* destinationViewController = segue.destinationViewController;
		EVEAssetListItem* asset = [sender object];
		destinationViewController.type = asset.type;
	}
	else if ([segue.identifier isEqualToString:@"NCAssetsContainerViewController"]) {
		NCAssetsContainerViewController* destinationViewController = segue.destinationViewController;
		EVEAssetListItem* asset = [sender object];
		destinationViewController.asset = asset;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCAssetsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	return data.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCAssetsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	return [[data.sections[section] assets] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCAssetsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	NCAssetsViewControllerDataSection* section = data.sections[sectionIndex];
	return [NSString stringWithFormat:@"%@ (%@)", section.title, [NSNumberFormatter neocomLocalizedStringFromInteger:section.assets.count]];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCAssetsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	NCAssetsViewControllerDataSection* section = data.sections[indexPath.section];
	EVEAssetListItem* asset = section.assets[indexPath.row];
	
	NCTableViewCell* cell = (NCTableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell)
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
	
	cell.imageView.image = [UIImage imageNamed:asset.type.typeSmallImageName];
	
	cell.textLabel.text = asset.title;
	cell.object = asset;
	
	if (asset.parent) {
		if (asset.owner)
			cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"In: %@ (%@)", nil), asset.parent.title, asset.owner];
		else
			cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"In: %@", nil), asset.parent.title];
	}
	
	else
		cell.detailTextLabel.text = asset.owner;
	
	return cell;
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	NCAssetsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	NCAssetsViewControllerDataSection* section = data.sections[indexPath.section];
	EVEAssetListItem* asset = section.assets[indexPath.row];
	if (asset.contents.count == 0)
		[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:cell];
	else
		[self performSegueWithIdentifier:@"NCAssetsContainerViewController" sender:cell];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	NSMutableArray* ids = [NSMutableArray new];
	for (NCAccount* account in self.accounts)
		[ids addObject:account.uuid];
	[ids sortedArrayUsingSelector:@selector(compare:)];
	
	return [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), [ids componentsJoinedByString:@","]];
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
											 NSMutableDictionary* groups = [NSMutableDictionary new];
											 NSMutableDictionary* categories = [NSMutableDictionary new];
											 
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
													 
													 EVEDBInvType* type = types[@(asset.typeID)];
													 if (!type) {
														 type = [EVEDBInvType invTypeWithTypeID:asset.typeID error:nil];
														 if (type) {
															 types[@(asset.typeID)] = type;
															 EVEDBInvGroup* group = groups[@(type.groupID)];
															 if (!group) {
																 group = type.group;
																 if (group) {
																	 groups[@(type.groupID)] = group;
																	 EVEDBInvCategory* category = categories[@(group.categoryID)];
																	 if (!category) {
																		 category = group.category;
																		 if (category) {
																			 categories[@(group.categoryID)] = category;
																		 }
																	 }
																	 else
																		 group.category = category;
																 }
															 }
															 else
																 type.group = group;
														 }
													 }
													 
													 asset.type = type;
													 
													 if (asset.locationID > 0) {
														 [locationIDs addObject:@(asset.locationID)];
														 if (type.groupID == 365) { // ControlTower
															 [controlTowers addObject:asset];
															 [itemIDs addObject:@(asset.itemID)];
														 }
														 else if (type.group.categoryID == NCControlTowerGroupID ||
																  type.group.categoryID == NCShipCategoryID ||
																  type.groupID == NCSecureContainerGroupID) {
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
														 eveLocations = [EVELocations locationsWithKeyID:account.apiKey.keyID vCode:account.apiKey.vCode cachePolicy:cachePolicy characterID:account.characterID ids:subArray corporate:corporate error:nil progressHandler:nil];
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
													 [sections addObject:section];
												 }];
											 }
											 
											 if (topLevelAssets.count > 0) {
												 NCAssetsViewControllerDataSection* section = [NCAssetsViewControllerDataSection new];
												 section.assets = topLevelAssets;
												 section.title = NSLocalizedString(@"Unknown location", nil);
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

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	
	if (account) {
		self.accounts = @[account];
	}

	
	if ([self isViewLoaded])
		[self reloadFromCache];
}

- (void) searchWithSearchString:(NSString*) searchString {
	NCAssetsViewControllerData* searchResults = [NCAssetsViewControllerData new];
	NCAssetsViewControllerData* data = self.data;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:nil
										 block:^(NCTask *task) {
											 if ([task isCancelled])
												 return;
											 if (searchString.length >= 2) {
												 __weak __block void (^weakSearch)(EVEAssetListItem*, NSMutableArray*);
												 void (^search)(EVEAssetListItem*, NSMutableArray*) = ^(EVEAssetListItem* asset, NSMutableArray* sectionAssets) {
													 if ((asset.title && [asset.title rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
														 (asset.type.typeName && [asset.type.typeName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
														 (asset.type.group.groupName && [asset.type.group.groupName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
														 (asset.type.group.category.categoryName && [asset.type.group.category.categoryName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
														 (asset.owner && [asset.owner rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
														 [sectionAssets addObject:asset];
													 }
													 for (EVEAssetListItem* item in asset.contents) {
														 if ([task isCancelled])
															 return;
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
															 if ([task isCancelled])
																 return;
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
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.searchResults = searchResults;
									 [self.searchDisplayController.searchResultsTableView reloadData];
								 }
							 }];
}

@end
