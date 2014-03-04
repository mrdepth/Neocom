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

@interface NCSkillPlanViewController ()<NSXMLParserDelegate>
@property (nonatomic, strong) NCTrainingQueue* trainingQueue;
@property (nonatomic, strong) NSArray* rows;
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

	self.trainingQueue = [[NCTrainingQueue alloc] initWithAccount:[NCAccount currentAccount]];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NSXMLParser* parser = [[NSXMLParser alloc] initWithData:self.xmlData];
											 parser.delegate = self;
											 [parser parse];
										 }
							 completionHandler:^(NCTask *task) {
								 self.rows = self.trainingQueue.skills;
								 [self.tableView reloadData];
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
								 [storage.managedObjectContext performBlockAndWait:^{
									 account.activeSkillPlan.trainingQueue = self.trainingQueue;
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
								 [storage.managedObjectContext performBlockAndWait:^{
									 NCSkillPlan* skillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:storage.managedObjectContext]
																   insertIntoManagedObjectContext:storage.managedObjectContext];
									 skillPlan.trainingQueue = self.trainingQueue;
									 skillPlan.name = self.skillPlanName;
									 skillPlan.account = account;
									 account.activeSkillPlan = skillPlan;
									 [storage saveContext];
								 }];
								 [self performSegueWithIdentifier:@"Unwind" sender:nil];
							 }
						 }
							 cancelBlock:nil] showFromBarButtonItem:sender animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.rows ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCSkillData* row = self.rows[indexPath.row];
	
	
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

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString:@"entry"]) {
		NSInteger typeID = [attributeDict[@"skillID"] integerValue];
		NSInteger level = [attributeDict[@"level"] integerValue];
		EVEDBInvType* skill = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
		if (skill)
			[self.trainingQueue addSkill:skill withLevel:level];
	}
	else if ([elementName isEqualToString:@"plan"]) {
		self.skillPlanName = [attributeDict valueForKey:@"name"];
	}
}

@end
