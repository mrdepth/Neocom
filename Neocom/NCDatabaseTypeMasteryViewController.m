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
#import "UIAlertView+Block.h"
#import "NCTableViewCell.h"
#import "NCDatabase.h"

@interface NCDatabaseTypeMasteryViewControllerRow : NSObject
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* detail;
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, strong) NCDBEveIcon* accessoryIcon;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSString* cellIdentifier;
@end

@interface NCDatabaseTypeMasteryViewController ()
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
		
		controller.type = row.object;
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
		[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Add to skill plan?", nil)
								 message:[NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]]
					   cancelButtonTitle:NSLocalizedString(@"No", nil)
					   otherButtonTitles:@[NSLocalizedString(@"Yes", nil)]
						 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != alertView.cancelButtonIndex) {
								 NCSkillPlan* skillPlan = [[NCAccount currentAccount] activeSkillPlan];
								 [skillPlan mergeWithTrainingQueue:trainingQueue];
							 }
						 }
							 cancelBlock:nil] show];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

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
	NCTableViewCell* cell = (NCTableViewCell*) tableViewCell;
	cell.titleLabel.text = row.title;
	cell.subtitleLabel.text = row.detail;
	cell.iconView.image = row.icon ? row.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.accessoryView = row.accessoryIcon ? [[UIImageView alloc] initWithImage:row.accessoryIcon.image.image] : nil;
}

#pragma mark - Private

- (void) reload {
	NCAccount* account = [NCAccount currentAccount];
	NSMutableArray* sections = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCDatabase* database = [NCDatabase sharedDatabase];
											 [database.backgroundManagedObjectContext performBlockAndWait:^{
												 NCDBInvType* type = (NCDBInvType*) [database.backgroundManagedObjectContext objectWithID:self.type.objectID];
												 NCDBCertMasteryLevel* masteryLevel = (NCDBCertMasteryLevel*) [database.backgroundManagedObjectContext objectWithID:self.masteryLevel.objectID];
												 
												 NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
												 NSMutableArray* rows = nil;
												 
												 NCDBEveIcon* skillIcon = [NCDBEveIcon eveIconWithIconFile:@"50_11"];
												 NCDBEveIcon* notKnownIcon = [NCDBEveIcon eveIconWithIconFile:@"38_194"];
												 NCDBEveIcon* lowLevelIcon = [NCDBEveIcon eveIconWithIconFile:@"38_193"];
												 NCDBEveIcon* knownIcon = [NCDBEveIcon eveIconWithIconFile:@"38_195"];
												 for (NCDBCertCertificate* certificate in [type.certificates sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"certificateName" ascending:YES]]]) {
													 NCDBCertMastery* mastery = [certificate.masteries objectAtIndex:masteryLevel.level];
													 NCTrainingQueue* sectionTrainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
													 [sectionTrainingQueue addMastery:mastery];
													 
													 rows = [NSMutableArray new];
													 [trainingQueue addMastery:mastery];
													 for (NCDBCertSkill* certSkill in [mastery.skills sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]]) {
														 NCTrainingQueue* skillTrainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
														 [skillTrainingQueue addSkill:certSkill.type withLevel:certSkill.skillLevel];
														 
														 EVECharacterSheetSkill* characerSkill = account.characterSheet.skillsMap[@(certSkill.type.typeID)];
														 
														 NCDatabaseTypeMasteryViewControllerRow* row = [NCDatabaseTypeMasteryViewControllerRow new];
														 row.title = [NSString stringWithFormat:@"%@ %d", certSkill.type.typeName, certSkill.skillLevel];
														 row.object = certSkill.type;
														 row.cellIdentifier = @"TypeCell";
														 row.icon = skillIcon;
														 
														 if (!characerSkill)
															 row.accessoryIcon = notKnownIcon;
														 else if (characerSkill.level >= certSkill.skillLevel)
															 row.accessoryIcon = lowLevelIcon;
														 else
															 row.accessoryIcon = knownIcon;
														 
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
												 
												 if (account && account.activeSkillPlan && trainingQueue.skills.count > 0) {
													 rows = [NSMutableArray new];
													 NCDatabaseTypeMasteryViewControllerRow* row = [NCDatabaseTypeMasteryViewControllerRow new];
													 row.title = NSLocalizedString(@"Add all skills to training plan", nil);
													 row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
													 row.icon = [NCDBEveIcon eveIconWithIconFile:@"50_13"];
													 row.object = trainingQueue;
													 [rows addObject:row];
													 
													 [sections insertObject:@{@"title": NSLocalizedString(@"Skill Plan", nil), @"rows": rows} atIndex:0];
												 }
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.sections = sections;
									 [self update];
								 }
							 }];
}

@end
