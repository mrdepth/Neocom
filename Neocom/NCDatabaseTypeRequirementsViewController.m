//
//  NCDatabaseTypeRequirementsViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 04.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeRequirementsViewController.h"
#import "UIColor+Neocom.h"
#import "NCDatabase.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCDatabaseTypeRequirementsViewControllerRow : NSObject
@property (nonatomic, strong) NSString* typeName;
@property (nonatomic, strong) NSManagedObjectID* iconID;
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, strong) NSManagedObjectID* typeID;
@end

@interface NCDatabaseTypeRequirementsViewControllerSection : NSObject
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, assign) NSInteger level;
@end

@implementation NCDatabaseTypeRequirementsViewControllerRow
@end

@implementation NCDatabaseTypeRequirementsViewControllerSection
@end

@interface NCDatabaseTypeRequirementsViewController()
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@property (nonatomic, strong) NSArray* sections;

@end

@implementation NCDatabaseTypeRequirementsViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	[self reload];
	self.refreshControl = nil;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.typeID = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCDatabaseTypeRequirementsViewControllerSection* section = self.sections[sectionIndex];
	return section.rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCDatabaseTypeRequirementsViewControllerSection* section = self.sections[sectionIndex];
	return [NSString stringWithFormat:NSLocalizedString(@"Level %ld", nil), (long) section.level];
}

#pragma mark - NCTableViewController

- (NSString *)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	NCDatabaseTypeRequirementsViewControllerSection* section = self.sections[indexPath.section];
	NCDatabaseTypeRequirementsViewControllerRow* row = section.rows[indexPath.row];
	if (!row.icon && row.iconID)
		row.icon = (NCDBEveIcon*) [self.databaseManagedObjectContext existingObjectWithID:row.iconID error:nil];
	
	cell.titleLabel.text = row.typeName;
	cell.iconView.image = row.icon.image.image ?: self.defaultTypeIcon.image.image;
	cell.object = row.typeID;
}

#pragma mark - Private

- (void) reload {
	NSManagedObjectContext* managedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
	[managedObjectContext performBlock:^{
		NSMutableDictionary* sections = [NSMutableDictionary new];
		
		NCDBInvType* type = (NCDBInvType*) [managedObjectContext existingObjectWithID:self.typeID error:nil];
		for (NCDBInvTypeRequiredSkill* requiredSkill in type.requiredForSkill) {
			if (requiredSkill.type) {
				NSInteger level = MAX(1, requiredSkill.skillLevel);
				NCDatabaseTypeRequirementsViewControllerSection* section = sections[@(level)];
				if (!section) {
					sections[@(level)] = section = [NCDatabaseTypeRequirementsViewControllerSection new];
					section.rows = [NSMutableArray new];
					section.level = level;
				}
				NCDatabaseTypeRequirementsViewControllerRow* row = [NCDatabaseTypeRequirementsViewControllerRow new];
				row.typeName = requiredSkill.type.typeName;
				row.iconID = [requiredSkill.type.icon objectID];
				row.typeID = [requiredSkill.type objectID];
				[section.rows addObject:row];
			}
		}
		[sections enumerateKeysAndObjectsUsingBlock:^(id key, NCDatabaseTypeRequirementsViewControllerSection* obj, BOOL *stop) {
			[obj.rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
		}];
		
		NSArray* values = [[sections allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"level" ascending:YES]]];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.sections = values;
			[self.tableView reloadData];
		});
	}];
}

@end
