//
//  NCDatabaseTypeMasteryViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 22.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeMasteryViewController.h"
#import "NCTrainingQueue.h"
#import "NCSkillHierarchy.h"
#import "NSString+Neocom.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCTableViewCell.h"
#import "NCDatabase.h"

@interface NCDatabaseTypeMasteryViewControllerRow : NSObject
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* detail;
@property (nonatomic, strong) NSManagedObjectID* iconID;
@property (nonatomic, strong) NSManagedObjectID* accessoryIconID;
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, strong) NCDBEveIcon* accessoryIcon;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSString* cellIdentifier;
@end

@interface NCDatabaseTypeMasteryViewController ()
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@property (nonatomic, strong) NSArray* sections;
- (void) reload;
@end

@implementation NCDatabaseTypeMasteryViewControllerRow
@end

@implementation NCDatabaseTypeMasteryViewController

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
	self.type = (NCDBInvType*) [self.databaseManagedObjectContext existingObjectWithID:self.typeID error:nil];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	self.title = self.type.typeName;
	self.refreshControl = nil;
	[self reload];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
	NCDatabaseTypeMasteryViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.typeID = [row.object objectID];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section][@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseTypeMasteryViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	if (row.object && [row.object isKindOfClass:[NCTrainingQueue class]]) {
		NCTrainingQueue* trainingQueue = row.object;
		UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add to skill plan?", nil)
																			message:[NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]]
																	 preferredStyle:UIAlertControllerStyleAlert];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			NCAccount* account = [NCAccount currentAccount];
			[account.managedObjectContext performBlock:^{
				[account.activeSkillPlan mergeWithTrainingQueue:trainingQueue completionBlock:nil];
			}];
		}]];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		[self presentViewController:controller animated:YES completion:nil];
	}
}

#pragma mark - NCTableViewController

// Customize the appearance of table view cells.
- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseTypeMasteryViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	NSString *cellIdentifier = row.cellIdentifier;
	if (!cellIdentifier)
		cellIdentifier = @"Cell";
	return cellIdentifier;
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCDatabaseTypeMasteryViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	cell.titleLabel.text = row.title;
	cell.subtitleLabel.text = row.detail;
	
	if (row.iconID && !row.icon)
		row.icon = (NCDBEveIcon*) [self.databaseManagedObjectContext existingObjectWithID:row.iconID error:nil];
	if (row.accessoryIconID && !row.accessoryIcon)
		row.accessoryIcon = (NCDBEveIcon*) [self.databaseManagedObjectContext existingObjectWithID:row.accessoryIconID error:nil];

	
	cell.iconView.image = row.icon ? row.icon.image.image : self.defaultTypeIcon.image.image;
	cell.accessoryView = row.accessoryIcon ? [[UIImageView alloc] initWithImage:row.accessoryIcon.image.image] : nil;
}

#pragma mark - Private

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	[self reload];
}

- (void) didChangeStorage:(NSNotification *)notification {
	[super didChangeStorage:notification];
	[self reload];
}

- (void) reload {
	NCAccount* account = [NCAccount currentAccount];
	
	void (^load)(EVECharacterSheet*) = ^(EVECharacterSheet* characterSheet) {
		NSManagedObjectContext* managedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		[managedObjectContext performBlock:^{
			NSMutableArray* sections = [NSMutableArray new];
			
			NCDBInvType* type = (NCDBInvType*) [managedObjectContext existingObjectWithID:self.typeID error:nil];
			NCDBCertMasteryLevel* masteryLevel = (NCDBCertMasteryLevel*) [managedObjectContext existingObjectWithID:self.masteryLevelID error:nil];
			
			NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet databaseManagedObjectContext:managedObjectContext];
			NSMutableArray* rows = nil;
			
			NCDBEveIcon* skillIcon = [managedObjectContext eveIconWithIconFile:@"50_11"];
			NCDBEveIcon* notKnownIcon = [managedObjectContext eveIconWithIconFile:@"38_194"];
			NCDBEveIcon* lowLevelIcon = [managedObjectContext eveIconWithIconFile:@"38_193"];
			NCDBEveIcon* knownIcon = [managedObjectContext eveIconWithIconFile:@"38_195"];
			for (NCDBCertCertificate* certificate in [type.certificates sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"certificateName" ascending:YES]]]) {
				NCDBCertMastery* mastery = [certificate.masteries objectAtIndex:masteryLevel.level];
				NCTrainingQueue* sectionTrainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet databaseManagedObjectContext:managedObjectContext];
				[sectionTrainingQueue addMastery:mastery];
				
				rows = [NSMutableArray new];
				[trainingQueue addMastery:mastery];
				for (NCDBCertSkill* certSkill in [mastery.skills sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]]) {
					NCTrainingQueue* skillTrainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet databaseManagedObjectContext:managedObjectContext];
					[skillTrainingQueue addSkill:certSkill.type withLevel:certSkill.skillLevel];
					
					EVECharacterSheetSkill* characerSkill = characterSheet.skillsMap[@(certSkill.type.typeID)];
					
					NCDatabaseTypeMasteryViewControllerRow* row = [NCDatabaseTypeMasteryViewControllerRow new];
					row.title = [NSString stringWithFormat:@"%@ %d", certSkill.type.typeName, certSkill.skillLevel];
					row.object = certSkill.type;
					row.cellIdentifier = @"TypeCell";
					row.iconID = [skillIcon objectID];
					
					if (!characerSkill)
						row.accessoryIconID = [notKnownIcon objectID];
					else if (characerSkill.level >= certSkill.skillLevel)
						row.accessoryIconID = [lowLevelIcon objectID];
					else
						row.accessoryIconID = [knownIcon objectID];
					
					if (skillTrainingQueue.trainingTime > 0.0)
						row.detail = [NSString stringWithTimeLeft:skillTrainingQueue.trainingTime];
					
					[rows addObject:row];
				}
				if (rows.count > 0) {
					NSString* title;
					if (sectionTrainingQueue.trainingTime > 0.0)
						title = [NSString stringWithFormat:@"%@ (%@)", mastery.certificate.certificateName, [NSString stringWithTimeLeft:sectionTrainingQueue.trainingTime]];
					else
						title = mastery.certificate.certificateName;
					[sections addObject:@{@"title": title, @"rows": rows}];
				}
			}
			
			if (account && trainingQueue.skills.count > 0) {
				rows = [NSMutableArray new];
				NCDatabaseTypeMasteryViewControllerRow* row = [NCDatabaseTypeMasteryViewControllerRow new];
				row.title = NSLocalizedString(@"Add all skills to training plan", nil);
				row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
				row.iconID = [[managedObjectContext eveIconWithIconFile:@"50_13"] objectID];
				row.object = trainingQueue;
				[rows addObject:row];
				
				[sections insertObject:@{@"title": NSLocalizedString(@"Skill Plan", nil), @"rows": rows} atIndex:0];
			}
			
			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.sections = sections;
				[self.tableView reloadData];
			});
		}];

	};

	if (account) {
		[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
			load(characterSheet);
		}];
	}
	else
		load(nil);

}

@end
