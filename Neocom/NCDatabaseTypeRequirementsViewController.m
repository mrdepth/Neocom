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

@interface NCDatabaseTypeRequirementsViewControllerSection : NSObject
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, assign) NSInteger level;
@end

@implementation NCDatabaseTypeRequirementsViewControllerSection
@end

@interface NCDatabaseTypeRequirementsViewController()
@property (nonatomic, strong) NSArray* sections;

@end

@implementation NCDatabaseTypeRequirementsViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
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
		
		controller.type = [sender object];
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

- (NSString*) recordID {
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	NCDatabaseTypeRequirementsViewControllerSection* section = self.sections[indexPath.section];
	NCDBInvType* row = section.rows[indexPath.row];
	cell.titleLabel.text = [row typeName];
	cell.iconView.image = row.icon.image.image ? row.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.object = row;
}

#pragma mark - Private

- (void) reload {

	NSMutableDictionary* sections = [NSMutableDictionary new];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCDatabase* database = [NCDatabase sharedDatabase];
											 [database.backgroundManagedObjectContext performBlockAndWait:^{
												 for (NCDBInvTypeRequiredSkill* requiredSkill in self.type.requiredForSkill) {
													 if (requiredSkill.type) {
														 NSInteger level = MAX(1, requiredSkill.skillLevel);
														 NCDatabaseTypeRequirementsViewControllerSection* section = sections[@(level)];
														 if (!section) {
															 sections[@(level)] = section = [NCDatabaseTypeRequirementsViewControllerSection new];
															 section.rows = [NSMutableArray new];
															 section.level = level;
														 }
														 [section.rows addObject:requiredSkill.type];
													 }
												 }
												 [sections enumerateKeysAndObjectsUsingBlock:^(id key, NCDatabaseTypeRequirementsViewControllerSection* obj, BOOL *stop) {
													 [obj.rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
												 }];
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.sections = [[sections allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"level" ascending:YES]]];
									 [self update];
								 }
							 }];

}

- (void) loadItemAttributes {
	NCAccount *account = [NCAccount currentAccount];
	NCCharacterAttributes* attributes = [account characterAttributes];
	if (!attributes)
		attributes = [NCCharacterAttributes defaultCharacterAttributes];
	
	}

@end
