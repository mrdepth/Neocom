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
#import "UIAlertView+Block.h"

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
	NCAccount* account = [NCAccount currentAccount];
	if (account)
		self.characterAttributes = [account characterAttributes];
	else
		self.characterAttributes = [NCCharacterAttributes defaultCharacterAttributes];
	if (!account.activeSkillPlan)
		self.navigationItem.rightBarButtonItem = nil;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = [sender skillData];
	}
}

- (IBAction)onTrain:(id)sender {
	[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Add to skill plan?", nil)
							 message:[NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:self.trainingQueue.trainingTime]]
				   cancelButtonTitle:NSLocalizedString(@"No", nil)
				   otherButtonTitles:@[NSLocalizedString(@"Yes", nil)]
					 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
						 if (selectedButtonIndex != alertView.cancelButtonIndex) {
							 NCSkillPlan* skillPlan = [[NCAccount currentAccount] activeSkillPlan];
							 [skillPlan mergeWithTrainingQueue:self.trainingQueue];
						 }
					 }
						 cancelBlock:nil] show];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCSkillData* row = self.trainingQueue.skills[indexPath.row];
	
	
	NCSkillCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
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
									  [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.characterAttributes skillpointsPerSecondForSkill:row] * 3600)]];
		cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), MAX(row.targetLevel, row.trainedLevel)];
		[cell.levelImageView setGIFImageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"level_%d%d%d", row.trainedLevel, row.targetLevel, row.active] withExtension:@"gif"]];
		cell.dateLabel.text = row.trainingTimeToLevelUp > 0 ? [NSString stringWithFormat:@"%@ (%.0f%%)", [NSString stringWithTimeLeft:row.trainingTimeToLevelUp], progress * 100] : nil;
	}
	else {
		cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ SP/h", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.characterAttributes skillpointsPerSecondForSkill:row] * 3600)]];
		cell.levelLabel.text = nil;
		cell.levelImageView.image = nil;
		cell.dateLabel.text = nil;
	}
	cell.titleLabel.text = row.skillName;
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (self.trainingQueue.skills.count > 0)
		return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NSString stringWithTimeLeft:self.trainingQueue.trainingTime], self.trainingQueue.skills.count];
	else
		return NSLocalizedString(@"Skill plan is empty", nil);
}


@end
