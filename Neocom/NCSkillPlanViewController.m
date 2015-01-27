//
//  NCSkillPlanViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 04.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillPlanViewController.h"
#import "NCSkillCell.h"
#import "UIImageView+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSString+Neocom.h"
#import "UIActionSheet+Block.h"
#import "NCStorage.h"

@interface NCSkillPlanViewController ()
@property (nonatomic, strong) NCTrainingQueue* trainingQueue;
@property (nonatomic, strong) NCCharacterAttributes* characterAttributes;
@end

@implementation NCSkillPlanViewController

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
	self.title = self.skillPlanName;
	self.refreshControl = nil;
	
	NCAccount* account = [NCAccount currentAccount];
	if (account)
		self.characterAttributes = [account characterAttributes];
	else
		self.characterAttributes = [NCCharacterAttributes defaultCharacterAttributes];

	__block NSString* skillPlanName = nil;
	__block NCTrainingQueue* trainingQueue;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 trainingQueue = [[NCTrainingQueue alloc] initWithAccount:[NCAccount currentAccount] xmlData:self.xmlData skillPlanName:&skillPlanName];
										 }
							 completionHandler:^(NCTask *task) {
								 if (skillPlanName)
									 self.title = self.skillPlanName = skillPlanName;
								 self.trainingQueue = trainingQueue;
								 [self update];
							 }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onAction:(id)sender {
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:@[NSLocalizedString(@"Replace Active Skill Plan", nil), NSLocalizedString(@"Merge with Active Skill Plan", nil), NSLocalizedString(@"Create new Skill Plan", nil)]
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex == 0) {
								 NCAccount* account = [NCAccount currentAccount];
								 NCStorage* storage = [NCStorage sharedStorage];
								 NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
								 [context performBlockAndWait:^{
									 account.activeSkillPlan.trainingQueue = self.trainingQueue;
									 [account.activeSkillPlan save];
									 [storage saveContext];
								 }];

								 [self performSegueWithIdentifier:@"Unwind" sender:nil];
							 }
							 else if (selectedButtonIndex == 1) {
								 NCAccount* account = [NCAccount currentAccount];
								 [account.activeSkillPlan mergeWithTrainingQueue:self.trainingQueue];
								 [self performSegueWithIdentifier:@"Unwind" sender:nil];
							 }
							 else if (selectedButtonIndex == 2) {
								 NCAccount* account = [NCAccount currentAccount];
								 NCStorage* storage = [NCStorage sharedStorage];
								 NSManagedObjectContext* context = [NSThread isMainThread] ? storage.managedObjectContext : storage.backgroundManagedObjectContext;
								 [context performBlockAndWait:^{
									 NCSkillPlan* skillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:context]
																   insertIntoManagedObjectContext:context];
									 skillPlan.trainingQueue = self.trainingQueue;
									 skillPlan.name = self.skillPlanName;
									 skillPlan.account = account;
									 account.activeSkillPlan = skillPlan;
									 [skillPlan save];
								 }];
								 [self performSegueWithIdentifier:@"Unwind" sender:nil];
							 }
						 }
							 cancelBlock:nil] showFromBarButtonItem:sender animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.trainingQueue ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.trainingQueue.skills.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCSkillData* row = self.trainingQueue.skills[indexPath.row];
	
	
	NCSkillCell* cell = nil;
	if (row.trainedLevel >= 0)
		cell = [tableView dequeueReusableCellWithIdentifier:@"NCSkillCell"];
	else
		cell = [tableView dequeueReusableCellWithIdentifier:@"NCSkillCompactCell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (self.trainingQueue.skills.count > 0)
		return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NSString stringWithTimeLeft:self.trainingQueue.trainingTime], (int32_t)self.trainingQueue.skills.count];
	else
		return NSLocalizedString(@"Skill plan is empty", nil);
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 42;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
		return UITableViewAutomaticDimension;

	NCSkillData* row = self.trainingQueue.skills[indexPath.row];

	UITableViewCell* cell = nil;
	if (row.trainedLevel >= 0)
		cell = [self tableView:tableView offscreenCellWithIdentifier:@"NCSkillCell"];
	else
		cell = [self tableView:tableView offscreenCellWithIdentifier:@"NCSkillCompactCell"];
	
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCSkillData* row = self.trainingQueue.skills[indexPath.row];
	
	
	NCSkillCell* cell = (NCSkillCell*) tableViewCell;
	cell.skillData = row;
	
	if (row.trainedLevel >= 0) {
		float progress = 0;
		
		if (row.targetLevel == row.trainedLevel + 1) {
			float startSkillPoints = [row skillPointsAtLevel:row.trainedLevel];
			float targetSkillPoints = [row skillPointsAtLevel:row.targetLevel];
			
			progress = (row.skillPoints - startSkillPoints) / (targetSkillPoints - startSkillPoints);
			if (progress > 1.0)
				progress = 1.0;
		}
		
		cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SP: %@ (%@ SP/h)", nil),
									  [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.skillPoints)],
									  [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.characterAttributes skillpointsPerSecondForSkill:row.type] * 3600)]];
		cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), MAX(row.targetLevel, row.trainedLevel)];
		[cell.levelImageView setGIFImageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"level_%d%d%d", row.trainedLevel, row.targetLevel, row.active] withExtension:@"gif"]];
		cell.dateLabel.text = row.trainingTimeToLevelUp > 0 ? [NSString stringWithFormat:@"%@ (%.0f%%)", [NSString stringWithTimeLeft:row.trainingTimeToLevelUp], progress * 100] : nil;
	}
	else {
		cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ SP/h", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.characterAttributes skillpointsPerSecondForSkill:row.type] * 3600)]];
		cell.levelLabel.text = nil;
		cell.levelImageView.image = nil;
		cell.dateLabel.text = nil;
	}
	cell.titleLabel.text = row.skillName;
}

@end
