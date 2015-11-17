//
//  NCFittingRequiredSkillsViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 08.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingRequiredSkillsViewController.h"
#import "NCSkillCell.h"
#import "NSString+Neocom.h"
#import "UIImageView+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCAccount.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCFittingRequiredSkillsViewController ()
@property (nonatomic, strong) NCCharacterAttributes* characterAttributes;
@end

@implementation NCFittingRequiredSkillsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if (segue.identifier && [segue.identifier rangeOfString:@"NCDatabaseTypeInfoViewController"].location != NSNotFound) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.typeID = [[self.databaseManagedObjectContext invTypeWithTypeID:[[sender skillData] typeID]] objectID];
	}
}

- (IBAction)onTrain:(id)sender {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add to skill plan?", nil)
																		message:[NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:self.trainingQueue.trainingTime]]
																 preferredStyle:UIAlertControllerStyleAlert];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		NCAccount* account = [NCAccount currentAccount];
		[account.managedObjectContext performBlock:^{
			NCSkillPlan* skillPlan = account.activeSkillPlan;
			[skillPlan mergeWithTrainingQueue:self.trainingQueue completionBlock:^(NCTrainingQueue *trainingQueue) {
				
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.trainingQueue.skills.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (self.trainingQueue.skills.count > 0)
		return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NSString stringWithTimeLeft:self.trainingQueue.trainingTime], (int32_t) self.trainingQueue.skills.count];
	else
		return NSLocalizedString(@"Skill plan is empty", nil);
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}


- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
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
									  [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.trainingQueue.characterAttributes skillpointsPerSecondForSkill:[self.databaseManagedObjectContext invTypeWithTypeID:row.typeID]] * 3600)]];
		cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), MAX(row.targetLevel, row.trainedLevel)];
		[cell.levelImageView setGIFImageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"level_%d%d%d", row.trainedLevel, row.targetLevel, row.active] withExtension:@"gif"]];
		cell.dateLabel.text = row.trainingTimeToLevelUp > 0 ? [NSString stringWithFormat:@"%@ (%.0f%%)", [NSString stringWithTimeLeft:row.trainingTimeToLevelUp], progress * 100] : nil;
	}
	else {
		cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ SP/h", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.trainingQueue.characterAttributes skillpointsPerSecondForSkill:[self.databaseManagedObjectContext invTypeWithTypeID:row.typeID]] * 3600)]];
		cell.levelLabel.text = nil;
		cell.levelImageView.image = nil;
		cell.dateLabel.text = nil;
	}
	cell.titleLabel.text = row.description;
}

@end
