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
		[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSString* skillPlanName;
				self.trainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet xmlData:self.xmlData skillPlanName:&skillPlanName databaseManagedObjectContext:self.databaseManagedObjectContext];
				self.characterAttributes = [[NCCharacterAttributes alloc] initWithCharacterSheet:characterSheet];
				self.title = self.skillPlanName = skillPlanName;
				[self.tableView reloadData];
			});
		}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onAction:(id)sender {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Replace Active Skill Plan", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		NCAccount* account = [NCAccount currentAccount];
		[account.managedObjectContext performBlock:^{
			NCSkillPlan* skillPlan = account.activeSkillPlan;
			[skillPlan clear];
			[skillPlan mergeWithTrainingQueue:self.trainingQueue completionBlock:^(NCTrainingQueue *trainingQueue) {
				[self performSegueWithIdentifier:@"Unwind" sender:nil];
			}];
		}];
	}]];

	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Merge with Active Skill Plan", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		NCAccount* account = [NCAccount currentAccount];
		[account.managedObjectContext performBlock:^{
			NCSkillPlan* skillPlan = account.activeSkillPlan;
			[skillPlan mergeWithTrainingQueue:self.trainingQueue completionBlock:^(NCTrainingQueue *trainingQueue) {
				[self performSegueWithIdentifier:@"Unwind" sender:nil];
			}];
		}];
	}]];

	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Create new Skill Plan", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		NCAccount* account = [NCAccount currentAccount];
		[account.managedObjectContext performBlock:^{
			NCSkillPlan* skillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:account.managedObjectContext]
										  insertIntoManagedObjectContext:account.managedObjectContext];
			skillPlan.name = self.skillPlanName;
			skillPlan.account = account;
			[skillPlan mergeWithTrainingQueue:self.trainingQueue completionBlock:^(NCTrainingQueue *trainingQueue) {
				[account.managedObjectContext performBlock:^{
					account.activeSkillPlan = skillPlan;
					[account.managedObjectContext save:nil];
					dispatch_async(dispatch_get_main_queue(), ^{
						[self performSegueWithIdentifier:@"Unwind" sender:nil];
					});
				}];
			}];
		}];
	}]];

	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[self presentViewController:controller animated:YES completion:nil];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (self.trainingQueue.skills.count > 0)
		return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NSString stringWithTimeLeft:self.trainingQueue.trainingTime], (int32_t)self.trainingQueue.skills.count];
	else
		return NSLocalizedString(@"Skill plan is empty", nil);
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.tableView.rowHeight;
}


#pragma mark - NCTableViewController

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCSkillData* row = self.trainingQueue.skills[indexPath.row];
	
	
	if (row.trainedLevel >= 0)
		return @"NCSkillCell";
	else
		return @"NCSkillCompactCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCSkillData* row = self.trainingQueue.skills[indexPath.row];
	
	
	NCSkillCell* cell = (NCSkillCell*) tableViewCell;
	cell.skillData = row;
	NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:row.typeID];
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
									  [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.characterAttributes skillpointsPerSecondForSkill:type] * 3600)]];
		cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), MAX(row.targetLevel, row.trainedLevel)];
		[cell.levelImageView setGIFImageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"level_%d%d%d", row.trainedLevel, row.targetLevel, row.active] withExtension:@"gif"]];
		cell.dateLabel.text = row.trainingTimeToLevelUp > 0 ? [NSString stringWithFormat:@"%@ (%.0f%%)", [NSString stringWithTimeLeft:row.trainingTimeToLevelUp], progress * 100] : nil;
	}
	else {
		cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ SP/h", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.characterAttributes skillpointsPerSecondForSkill:type] * 3600)]];
		cell.levelLabel.text = nil;
		cell.levelImageView.image = nil;
		cell.dateLabel.text = nil;
	}
	cell.titleLabel.text = row.description;
}

@end
