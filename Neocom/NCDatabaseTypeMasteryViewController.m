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

@interface NCDatabaseTypeMasteryViewControllerRow : NSObject
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* detail;
@property (nonatomic, copy) NSString* imageName;
@property (nonatomic, copy) NSString* accessoryImageName;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSString* cellIdentifier;
@end

@interface NCDatabaseTypeMasteryViewController ()
@property (nonatomic, strong) NSArray* sections;
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
	
	NCAccount* account = [NCAccount currentAccount];
	NSMutableArray* sections = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
											 NSMutableArray* rows = nil;
											 
											 for (EVEDBCertMastery* mastery in self.type.masteries[self.masteryLevel]) {
												 NCTrainingQueue* sectionTrainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
												 [sectionTrainingQueue addMastery:mastery];
												 
												 rows = [NSMutableArray new];
												 [trainingQueue addMastery:mastery];
												 for (EVEDBCertSkill* certSkill in mastery.certificate.skills[mastery.masteryLevel]) {
													 NCTrainingQueue* skillTrainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
													 [skillTrainingQueue addSkill:certSkill.skill withLevel:certSkill.skillLevel];
													 
													 EVECharacterSheetSkill* characerSkill = account.characterSheet.skillsMap[@(certSkill.skillID)];
													 
													 NCDatabaseTypeMasteryViewControllerRow* row = [NCDatabaseTypeMasteryViewControllerRow new];
													 row.title = [NSString stringWithFormat:@"%@ %d", certSkill.skill.typeName, certSkill.skillLevel];
													 row.object = certSkill.skill;
													 row.cellIdentifier = @"TypeCell";
													 
													 if (!characerSkill) {
														 row.imageName = @"Icons/icon50_11.png";
														 row.accessoryImageName = @"Icons/icon38_194.png";
													 }
													 else if (characerSkill.level >= certSkill.skillLevel) {
														 row.imageName = @"Icons/icon50_11.png";
														 row.accessoryImageName = @"Icons/icon38_193.png";
													 }
													 else {
														 row.imageName = @"Icons/icon50_11.png";
														 row.accessoryImageName = @"Icons/icon38_195.png";
													 }
													 
													 if (skillTrainingQueue.trainingTime > 0.0)
														 row.detail = [NSString stringWithTimeLeft:skillTrainingQueue.trainingTime];
													 
													 [rows addObject:row];
												 }
												 if (rows.count > 0) {
													 NSString* title;
													 if (sectionTrainingQueue.trainingTime > 0.0)
														 title = [NSString stringWithFormat:@"%@ (%@)", mastery.certificate.name, [NSString stringWithTimeLeft:sectionTrainingQueue.trainingTime]];
													 else
														 title = mastery.certificate.name;
													 [sections addObject:@{@"title": title, @"rows": rows}];
												 }
											 }
											 
											 if (account && account.activeSkillPlan && trainingQueue.skills.count > 0) {
												 rows = [NSMutableArray new];
												 NCDatabaseTypeMasteryViewControllerRow* row = [NCDatabaseTypeMasteryViewControllerRow new];
												 row.title = NSLocalizedString(@"Add all skills to training plan", nil);
												 row.detail = [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]];
												 row.imageName = @"Icons/icon50_13.png";
												 row.object = trainingQueue;
												 [rows addObject:row];
												 
												 [sections insertObject:@{@"title": NSLocalizedString(@"Skill Plan", nil), @"rows": rows} atIndex:0];
											 }

										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.sections = sections;
									 [self.tableView reloadData];
								 }
							 }];
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

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDatabaseTypeMasteryViewControllerRow* row = self.sections[indexPath.section][@"rows"][indexPath.row];
	NSString *cellIdentifier = row.cellIdentifier;
	if (!cellIdentifier)
		cellIdentifier = @"Cell";
	
	NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	cell.titleLabel.text = row.title;
	cell.subtitleLabel.text = row.detail;
	cell.iconView.image = [UIImage imageNamed:row.imageName ? row.imageName : @"Icons/icon105_32.png"];
	
	cell.accessoryView = row.accessoryImageName ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:row.accessoryImageName]] : nil;
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

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

@end
