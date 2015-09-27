//
//  NCAssetsContainerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 14.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAssetsContainerViewController.h"
#import "NSArray+Neocom.h"
#import "EVEAssetListItem+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCTableViewCell.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCFittingShipViewController.h"
#import <objc/runtime.h>

@interface EVEAssetListItem (NCDBInvType)
@property (nonatomic, strong) NCDBInvType* type;
@end

@implementation EVEAssetListItem(NCDBInvType)

- (NCDBInvType*) type {
	NCDBInvType* type = objc_getAssociatedObject(self, (const void*) @"type");
	return type;
}

- (void) setType:(NCDBInvType *)type {
	objc_setAssociatedObject(self, (const void*) @"type", type, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface NCAssetsContainerViewControllerSection: NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* assets;
@end

@implementation NCAssetsContainerViewControllerSection

@end

@interface NCAssetsContainerViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSArray* searchResults;
@property (nonatomic, strong) NSMutableDictionary* types;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@property (nonatomic, strong) NSArray* typeIDs;
@end

@implementation NCAssetsContainerViewController

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
	if (self.asset.title)
		self.title = self.asset.title;
	self.refreshControl = nil;
	NSMutableArray* sections = [NSMutableArray new];
	
	self.types = [NSMutableDictionary new];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];

	NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.asset.typeID];
	
	if (type.group.category.categoryID != NCShipCategoryID &&
		type.group.groupID != NCControlTowerGroupID)
		self.navigationItem.rightBarButtonItem = nil;
	
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        if (!self.searchContentsController) {
            self.searchController = [[UISearchController alloc] initWithSearchResultsController:[self.storyboard instantiateViewControllerWithIdentifier:@"NCAssetsContainerViewController"]];
        }
        else {
            self.tableView.tableHeaderView = nil;
            return;
        }
    }

	NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
	[databaseManagedObjectContext performBlock:^{

		NCDBInvType* type = [databaseManagedObjectContext invTypeWithTypeID:self.asset.typeID];
		
		NSMutableDictionary* types = [NSMutableDictionary new];
		for (EVEAssetListItem* asset in self.asset.contents) {
			asset.type = types[@(asset.typeID)];
			if (!asset.type) {
				asset.type = [databaseManagedObjectContext invTypeWithTypeID:asset.typeID];
				if (asset.type)
					types[@(asset.typeID)] = asset.type;
			}
		}

		if (type.group.category.categoryID == NCShipCategoryID) { // Ship
			NSMutableArray* hiSlots = [NSMutableArray new];
			NSMutableArray* medSlots = [NSMutableArray new];
			NSMutableArray* lowSlots = [NSMutableArray new];
			NSMutableArray* rigSlots = [NSMutableArray new];
			NSMutableArray* subsystemSlots = [NSMutableArray new];
			NSMutableArray* droneBay = [NSMutableArray new];
			NSMutableArray* cargo = [NSMutableArray new];
			
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
				if (array.count > 0) {
					NCAssetsContainerViewControllerSection* section = [NCAssetsContainerViewControllerSection new];
					section.title = titles[i];
					section.assets = array;
					[sections addObject:section];
				}
			}
			
		}
		else if (type.group.groupID == NCHangarOrOfficeGroupID) { //Hangar or Office
			NSMutableArray* groups = [[self.asset.contents arrayGroupedByKey:@"flag"] mutableCopy];
			
			[groups sortUsingComparator:^NSComparisonResult(NSArray* obj1, NSArray* obj2) {
				EVEAssetListItem* asset1 = obj1[0];
				EVEAssetListItem* asset2 = obj2[0];
				if (asset1.flag > asset2.flag)
					return NSOrderedDescending;
				else if (asset2.flag < asset2.flag)
					return NSOrderedAscending;
				else
					return NSOrderedSame;
			}];
			
			for (NSArray* group in groups) {
				NSString* title;
				EVEInventoryFlag flag = [group[0] flag];
				if (flag == EVEInventoryFlagHangar)
					title = NSLocalizedString(@"Hangar 1", nil);
				else if (flag >= EVEInventoryFlagCorpSAG2 && flag <= EVEInventoryFlagCorpSAG7) {
					int32_t i = flag - EVEInventoryFlagCorpSAG2 + 2;
					title = [NSString stringWithFormat:NSLocalizedString(@"Hangar %d", nil), i];
				}
				else
					title = NSLocalizedString(@"Unknown hangar", nil);
				NCAssetsContainerViewControllerSection* section = [NCAssetsContainerViewControllerSection new];
				section.title = title;
				section.assets = [group sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
				[sections addObject:section];
			}
		}
		else if (type.group.groupID == NCShipMaintenanceArrayGroupID) { //Ship Maintenance Array
			NSMutableArray* groups = [[self.asset.contents arrayGroupedByKey:@"type.group.groupID"] mutableCopy];
			
			[groups sortUsingComparator:^NSComparisonResult(NSArray* obj1, NSArray* obj2) {
				EVEAssetListItem* asset1 = obj1[0];
				EVEAssetListItem* asset2 = obj2[0];
				return [asset1.type.group.groupName compare:asset2.type.group.groupName];
			}];
			
			for (NSArray* group in groups) {
				EVEAssetListItem* item = group[0];
				NCAssetsContainerViewControllerSection* section = [NCAssetsContainerViewControllerSection new];
				section.title = item.type.group.groupName;
				section.assets = [group sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
				[sections addObject:section];
			}
		}
		else {
			NSMutableArray* groups = [[self.asset.contents arrayGroupedByKey:@"type.group.category.categoryID"] mutableCopy];
			
			[groups sortUsingComparator:^NSComparisonResult(NSArray* obj1, NSArray* obj2) {
				EVEAssetListItem* asset1 = obj1[0];
				EVEAssetListItem* asset2 = obj2[0];
				return [asset1.type.group.category.categoryName compare:asset2.type.group.category.categoryName];
			}];
			
			for (NSArray* group in groups) {
				EVEAssetListItem* item = group[0];
				NCAssetsContainerViewControllerSection* section = [NCAssetsContainerViewControllerSection new];
				section.title = item.type.group.category.categoryName;
				section.assets = [group sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]];
				[sections addObject:section];
			}
		}
		NSArray* typeIDs = [types allKeys];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.typeIDs = typeIDs;
			self.sections = sections;
			[self.tableView reloadData];
		});
	}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:@"NCAssetsContainerViewController"]) {
		EVEAssetListItem* asset = [sender object];
		return asset.contents.count > 0;
	}
	else
		return YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
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
	else if ([segue.identifier isEqualToString:@"NCFittingShipViewController"]) {
		NCFittingShipViewController* destinationViewController = segue.destinationViewController;
		NCShipFit* fit = [[NCShipFit alloc] initWithAsset:self.asset];
		destinationViewController.fit = fit;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NSArray* sections = tableView == self.tableView && !self.searchContentsController ? self.sections : self.searchResults;
	return sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* sections = tableView == self.tableView && !self.searchContentsController ? self.sections : self.searchResults;
	return [[sections[section] assets] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NSArray* sections = tableView == self.tableView && !self.searchContentsController ? self.sections : self.searchResults;
	NCAssetsContainerViewControllerSection* section = sections[sectionIndex];
	return [NSString stringWithFormat:@"%@ (%@)", section.title, [NSNumberFormatter neocomLocalizedStringFromInteger:section.assets.count]];
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	NSArray* sections = tableView == self.tableView && !self.searchContentsController ? self.sections : self.searchResults;
	NCAssetsContainerViewControllerSection* section = sections[indexPath.section];
	EVEAssetListItem* asset = section.assets[indexPath.row];
	if (asset.contents.count == 0)
		[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:cell];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) searchWithSearchString:(NSString*) searchString completionBlock:(void (^)())completionBlock{
	NSMutableArray* searchResults = [NSMutableArray new];
	NSArray* sections = self.sections;
	
	if (searchString.length > 0 && self.typeIDs.count > 0) {
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		[databaseManagedObjectContext performBlock:^{
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.predicate = [NSPredicate predicateWithFormat:@"typeID IN %@ AND (typeName CONTAINS[C] %@ OR group.groupName CONTAINS[C] %@ OR group.category.categoryName CONTAINS[C] %@)", self.typeIDs, searchString, searchString, searchString];
			request.resultType = NSDictionaryResultType;
			request.propertiesToFetch = @[[[NSEntityDescription entityForName:@"InvType" inManagedObjectContext:databaseManagedObjectContext] propertiesByName][@"typeID"]];
			NSArray* filteredTypeIDs = [[databaseManagedObjectContext executeFetchRequest:request error:nil] valueForKey:@"typeID"];
			
			void (^search)(EVEAssetListItem*, NSMutableArray*) = ^(EVEAssetListItem* asset, NSMutableArray* sectionAssets) {
				if ([filteredTypeIDs containsObject:@(asset.typeID)]) {
					[sectionAssets addObject:asset];
				}
			};
			
			for (NCAssetsContainerViewControllerSection* section in sections) {
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
					NCAssetsContainerViewControllerSection* searchSection = [NCAssetsContainerViewControllerSection new];
					searchSection.assets = sectionAssets;
					searchSection.title = section.title;
					[searchResults addObject:searchSection];
				}
			}
			
			self.searchResults = searchResults;
			if (self.searchController) {
				NCAssetsContainerViewController* searchResultsController = (NCAssetsContainerViewController*) self.searchController.searchResultsController;
				searchResultsController.searchResults = self.searchResults;
			}
			completionBlock();
			
		}];
	}
	else {
		self.searchResults = nil;
		if (self.searchController) {
			NCAssetsContainerViewController* searchResultsController = (NCAssetsContainerViewController*) self.searchController.searchResultsController;
			searchResultsController.searchResults = self.searchResults;
		}
		completionBlock();
	}
}

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NSArray* sections = tableView == self.tableView && !self.searchContentsController ? self.sections : self.searchResults;
	NCAssetsContainerViewControllerSection* section = sections[indexPath.section];
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
}

@end
