//
//  NCShoppingAssetsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 06.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingAssetsViewController.h"
#import "NCLocationsManager.h"
#import <EVEAPI/EVEAPI.h>
#import "EVEAssetListItem+Neocom.h"

@interface NCShoppingAssetsViewControllerRow : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, assign) NSInteger quantity;
@property (nonatomic, strong) id containerID;
@property (nonatomic, strong) UIImage* icon;
@end

@interface NCShoppingAssetsViewControllerSection : NSObject
@property (nonatomic, assign) float security;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* rows;
@end


@implementation NCShoppingAssetsViewControllerRow
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
	EVEAssetListItem* asset = [self.assets lastObject];
	self.title = asset.typeName;
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
	NCShoppingAssetsViewControllerRow* row = section.rows[indexPath.row];
	
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	cell.iconView.image = row.icon;
	
	cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), (int) row.quantity];
	cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"In %@", nil), row.title];
	cell.object = row;
	
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
	NSMutableDictionary* dic = [NSMutableDictionary new];
	
	id containerID = nil;
	
	for (EVEAssetListItem* asset in self.assets) {
		int64_t locationID = 0;
		if (asset.parent) {
			locationID = asset.parent.locationID;
			containerID = @(asset.parent.itemID);
		}
		else {
			locationID = asset.locationID;
			containerID = @(asset.flag);
		}
		
		NSMutableDictionary* rows = dic[@(locationID)];
		if (!rows)
			dic[@(locationID)] = rows = [NSMutableDictionary new];
		
		NCShoppingAssetsViewControllerRow* row = rows[containerID];
		if (!row) {
			rows[containerID] = row = [NCShoppingAssetsViewControllerRow new];
			if (asset.parent) {
				row.title = asset.parent.title;
				NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:asset.parent.typeID];
				row.icon = type.icon.image.image ?: [self.databaseManagedObjectContext defaultTypeIcon].image.image;
			}
			else {
				row.title = NSLocalizedString(@"Hangar", nil);
				row.icon = [UIImage imageNamed:@"stationcontainer.png"];
			}
		}
		row.quantity += asset.quantity;
	}
	[[NCLocationsManager defaultManager] requestLocationsNamesWithIDs:dic.allKeys completionBlock:^(NSDictionary *locationsNames) {
		[dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NCShoppingAssetsViewControllerSection* section = [NCShoppingAssetsViewControllerSection new];
			section.rows = [[obj allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
			NCLocationsManagerItem* location = locationsNames[key];
			if (location)
				section.title = location.name;
			else
				section.title = NSLocalizedString(@"Unknown location", nil);
			[sections addObject:section];
		}];
		[sections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
		self.sections = sections;
		[self.tableView reloadData];
	}];
}

@end
