//
//  NCShoppingAssetsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 06.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingAssetsViewController.h"
#import "NCLocationsManager.h"
#import "EVEOnlineAPI.h"
#import "EVEAssetListItem+Neocom.h"

@interface NCShoppingAssetsViewControllerSection : NSObject
@property (nonatomic, assign) float security;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* rows;
@end

@implementation NCShoppingAssetsViewControllerSection;

@end

@interface NCShoppingAssetsViewController()
@property (nonatomic, strong) NSArray* sections;
- (void) reload;
@end

@implementation NCShoppingAssetsViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.refreshControl = nil;
	[self reload];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCShoppingAssetsViewControllerSection* section = self.sections[sectionIndex];
	return section.rows.count;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCShoppingAssetsViewControllerSection* section = self.sections[sectionIndex];
	return section.title;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCShoppingAssetsViewControllerSection* section = self.sections[indexPath.section];
	EVEAssetListItem* asset = section.rows[indexPath.row];
	
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	cell.iconView.image = asset.type.icon ? asset.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	
	cell.titleLabel.text = asset.type.typeName;
	cell.subtitleLabel.text = [NSString stringWithFormat:@"x%d", asset.quantity];
	cell.object = asset;
	
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		if (asset.parent) {
			if (asset.owner)
				cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"In: %@ (%@)", nil), asset.parent.title, asset.owner];
			else
				cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"In: %@", nil), asset.parent.title];
		}
	}
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) didChangeStorage {
	[self reload];
}

#pragma mark - Private

- (void) reload {
	NSMutableArray* sections = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NSMutableDictionary* dic = [NSMutableDictionary new];
											 
											 for (EVEAssetListItem* asset in self.assets) {
												 int32_t locationID = 0;
												 if (asset.locationID > 0 )
													 locationID = asset.locationID;
												 else
													 locationID = asset.parent.locationID;
												 NSMutableArray* array = dic[@(locationID)];
												 if (!array)
													 dic[@(locationID)] = array = [NSMutableArray new];
												 [array addObject:asset];
											 }
											 NSDictionary* locations = [[NCLocationsManager defaultManager] locationsNamesWithIDs:dic.allKeys];
											 
											 [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
												 NCShoppingAssetsViewControllerSection* section = [NCShoppingAssetsViewControllerSection new];
												 section.rows = obj;
												 NCLocationsManagerItem* location = locations[key];
												 if (location)
													 section.title = location.name;
												 else
													 section.title = NSLocalizedString(@"Unknown location", nil);
												 [sections addObject:section];
											 }];
											 [sections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.sections = sections;
									 [self.tableView reloadData];
								 }
							 }];
}

@end
