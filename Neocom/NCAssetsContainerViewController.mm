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

@interface NCAssetsContainerViewControllerSection: NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* assets;
@end

@implementation NCAssetsContainerViewControllerSection

@end

@interface NCAssetsContainerViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSArray* searchResults;
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
	
	if (self.asset.type.group.category.categoryID != NCShipCategoryID &&
		self.asset.type.group.groupID != NCControlTowerGroupID)
		self.navigationItem.rightBarButtonItem = nil;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 if (self.asset.type.group.category.categoryID == NCShipCategoryID) { // Ship
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
											 else if (self.asset.type.group.groupID == NCHangarOrOfficeGroupID) { //Hangar or Office
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
											 else if (self.asset.type.group.groupID == NCShipMaintenanceArrayGroupID) { //Ship Maintenance Array
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
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.sections = sections;
									 [self update];
								 }
							 }];
	// Do any additional setup after loading the view.
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
		controller.type = (id) asset.type;
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
	NSArray* sections = tableView == self.tableView ? self.sections : self.searchResults;
	return sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* sections = tableView == self.tableView ? self.sections : self.searchResults;
	return [[sections[section] assets] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NSArray* sections = tableView == self.tableView ? self.sections : self.searchResults;
	NCAssetsContainerViewControllerSection* section = sections[sectionIndex];
	return [NSString stringWithFormat:@"%@ (%@)", section.title, [NSNumberFormatter neocomLocalizedStringFromInteger:section.assets.count]];
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	NSArray* sections = tableView == self.tableView ? self.sections : self.searchResults;
	NCAssetsContainerViewControllerSection* section = sections[indexPath.section];
	EVEAssetListItem* asset = section.assets[indexPath.row];
	if (asset.contents.count == 0)
		[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:cell];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) searchWithSearchString:(NSString*) searchString {
	NSMutableArray* searchResults = [NSMutableArray new];
	NSArray* sections = self.sections;
	
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
												 
												 for (NCAssetsContainerViewControllerSection* section in sections) {
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
														 NCAssetsContainerViewControllerSection* searchSection = [NCAssetsContainerViewControllerSection new];
														 searchSection.assets = sectionAssets;
														 searchSection.title = section.title;
														 [searchResults addObject:searchSection];
													 }
												 }
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.searchResults = searchResults;
									 [self.searchDisplayController.searchResultsTableView reloadData];
								 }
							 }];
}

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NSArray* sections = tableView == self.tableView ? self.sections : self.searchResults;
	NCAssetsContainerViewControllerSection* section = sections[indexPath.section];
	EVEAssetListItem* asset = section.assets[indexPath.row];
	
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	cell.iconView.image = asset.type.icon ? asset.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	
	cell.titleLabel.text = asset.title;
	cell.object = asset;
}

@end
