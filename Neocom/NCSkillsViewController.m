//
//  NCSkillsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillsViewController.h"
#import "NSArray+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSString+Neocom.h"
#import "UIActionSheet+Block.h"
#import "NCSkillCell.h"
#import "UIImageView+Neocom.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NSArray+Neocom.h"
#import "NSData+Neocom.h"
#import "NCCharacterAttributesCell.h"

@interface NCSkillsViewControllerDataSection : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) EVEDBInvGroup* group;
@end

@interface NCSkillsViewController ()
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) NSArray* allSkillsSections;
@property (nonatomic, strong) NSArray* knownSkillsSections;
@property (nonatomic, strong) NSArray* notKnownSkillsSections;
@property (nonatomic, strong) NSArray* canTrainSkillsSections;

@end

@implementation NCSkillsViewControllerDataSection;

@end

@implementation NCSkillsViewController

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
	self.mode = [[NSUserDefaults standardUserDefaults] integerForKey:NCSettingsSkillsViewControllerModeKey];
	self.modeSegmentedControl.selectedSegmentIndex = self.mode;
	self.refreshControl = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onChangeMode:(id)sender {
	self.mode = self.modeSegmentedControl.selectedSegmentIndex;
	[[NSUserDefaults standardUserDefaults] setInteger:self.mode forKey:NCSettingsSkillsViewControllerModeKey];
	[self.tableView reloadData];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if (segue.identifier && [segue.identifier rangeOfString:@"NCDatabaseTypeInfoViewController"].location != NSNotFound) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.type = [sender skillData];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	switch (self.mode) {
		case NCSkillsViewControllerModeKnownSkills:
			return self.knownSkillsSections.count;
		case NCSkillsViewControllerModeAllSkills:
			return self.allSkillsSections.count;
		case NCSkillsViewControllerModeNotKnownSkills:
			return self.notKnownSkillsSections.count;
		case NCSkillsViewControllerModeCanTrainSkills:
			return self.canTrainSkillsSections.count;
		default:
			return 0;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (self.mode) {
		case NCSkillsViewControllerModeKnownSkills:
			return [[self.knownSkillsSections[section] rows] count];
		case NCSkillsViewControllerModeAllSkills:
			return [[self.allSkillsSections[section] rows] count];
		case NCSkillsViewControllerModeNotKnownSkills:
			return [[self.notKnownSkillsSections[section] rows] count];
		case NCSkillsViewControllerModeCanTrainSkills:
			return [[self.canTrainSkillsSections[section] rows] count];
		default:
			return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCSkillData* row;
	
	switch (self.mode) {
		case NCSkillsViewControllerModeKnownSkills:
			row = [self.knownSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		case NCSkillsViewControllerModeAllSkills:
			row = [self.allSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		case NCSkillsViewControllerModeNotKnownSkills:
			row = [self.notKnownSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		case NCSkillsViewControllerModeCanTrainSkills:
			row = [self.canTrainSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		default:
			break;
	}

	NCSkillCell* cell = nil;
	if (row.trainedLevel >= 0)
		cell = [tableView dequeueReusableCellWithIdentifier:@"NCSkillCell"];
	else
		cell = [tableView dequeueReusableCellWithIdentifier:@"NCSkillCompactCell"];

	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (self.mode) {
		case NCSkillsViewControllerModeKnownSkills:
			return [self.knownSkillsSections[section] title];
		case NCSkillsViewControllerModeAllSkills:
			return [self.allSkillsSections[section] title];
		case NCSkillsViewControllerModeNotKnownSkills:
			return [self.notKnownSkillsSections[section] title];
		case NCSkillsViewControllerModeCanTrainSkills:
			return [self.canTrainSkillsSections[section] title];
		default:
			return 0;
	}
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 42;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	NCSkillData* row;
	
	switch (self.mode) {
		case NCSkillsViewControllerModeKnownSkills:
			row = [self.knownSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		case NCSkillsViewControllerModeAllSkills:
			row = [self.allSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		case NCSkillsViewControllerModeNotKnownSkills:
			row = [self.notKnownSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		case NCSkillsViewControllerModeCanTrainSkills:
			row = [self.canTrainSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		default:
			break;
	}
	
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
	NCSkillData* row;
	
	switch (self.mode) {
		case NCSkillsViewControllerModeKnownSkills:
			row = [self.knownSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		case NCSkillsViewControllerModeAllSkills:
			row = [self.allSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		case NCSkillsViewControllerModeNotKnownSkills:
			row = [self.notKnownSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		case NCSkillsViewControllerModeCanTrainSkills:
			row = [self.canTrainSkillsSections[indexPath.section] rows][indexPath.row];
			break;
		default:
			break;
	}
		
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
									  [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.account.characterAttributes skillpointsPerSecondForSkill:row] * 3600)]];
		cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), MAX(row.targetLevel, row.trainedLevel)];
		[cell.levelImageView setGIFImageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"level_%d%d%d", row.trainedLevel, row.targetLevel, row.active] withExtension:@"gif"]];
		cell.dateLabel.text = row.trainingTimeToLevelUp > 0 ? [NSString stringWithFormat:@"%@ (%.0f%%)", [NSString stringWithTimeLeft:row.trainingTimeToLevelUp], progress * 100] : nil;
	}
	else {
		cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ SP/h", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.account.characterAttributes skillpointsPerSecondForSkill:row] * 3600)]];
		cell.levelLabel.text = nil;
		cell.levelImageView.image = nil;
		cell.dateLabel.text = nil;
	}
	cell.titleLabel.text = row.skillName;
}


- (void) update {
	NCAccount* account = [NCAccount currentAccount];
	self.account = account;
	
	[super update];
	
	EVESkillQueue* skillQueue = self.account.skillQueue;
	EVECharacterSheet* characterSheet = self.account.characterSheet;
	NCCharacterAttributes* characterAttributes = self.account.characterAttributes;

	NSMutableArray* knownSkillsSections = [NSMutableArray new];
	NSMutableArray* allSkillsSections = [NSMutableArray new];
	NSMutableArray* canTrainSkillsSection = [NSMutableArray new];
	NSMutableArray* notKnownSkillsSections = [NSMutableArray new];

	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {

											 NSMutableDictionary* allSkills = [[NSMutableDictionary alloc] init];
											 
											 [[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT a.* FROM invTypes as a, invGroups as b where a.groupID=b.groupID and b.categoryID=16 and a.published = 1"
																				resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																					if ([task isCancelled])
																						*needsMore = NO;
																					NCSkillData* skillData = [[NCSkillData alloc] initWithStatement:stmt];
																					skillData.trainedLevel = -1;
																					allSkills[@(skillData.typeID)] = skillData;
																				}];
											 
											 
											 
											 NSMutableArray* knownSkills = [NSMutableArray array];

											 for (EVECharacterSheetSkill* characterSheetSkill in characterSheet.skills) {
												 NCSkillData* skillData = allSkills[@(characterSheetSkill.typeID)];
												 if (skillData) {
													 skillData.trainedLevel = characterSheetSkill.level;
													 skillData.skillPoints = characterSheetSkill.skillpoints;
													 skillData.characterAttributes = characterAttributes;
													 [knownSkills addObject:skillData];
												 }
											 }
											 if ([task isCancelled])
												 return;
											 
											 [knownSkills sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
											 
											 for (EVESkillQueueItem *item in skillQueue.skillQueue) {
												 NCSkillData* skillData = allSkills[@(item.typeID)];
												 if (!skillData)
													 continue;
												 
												 skillData.targetLevel = MAX(skillData.targetLevel, item.level);
												 if (item.queuePosition == 0)
													 skillData.active = YES;
											 }
											 
											 
											 if ([task isCancelled])
												 return;
											 
											 for (NSArray* skills in [knownSkills arrayGroupedByKey:@"groupID"]) {
												 float skillPoints = 0;
												 for (NCSkillData* skill in skills) {
													 skillPoints += skill.skillPoints;
												 }
												 NSString* title = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ skillpoints)", nil),
																	[[skills[0] group] groupName],
																	[NSNumberFormatter neocomLocalizedStringFromNumber:@(skillPoints)]];
												 NCSkillsViewControllerDataSection* section = [NCSkillsViewControllerDataSection new];
												 section.title = title;
												 section.rows = skills;
												 section.group = [skills[0] group];
												 [knownSkillsSections addObject:section];
											 }
											 [knownSkillsSections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
											 
											 if ([task isCancelled])
												 return;
											 
											 for (NSArray* skills in [[[allSkills allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]] arrayGroupedByKey:@"groupID"]) {
												 float skillPoints = 0;
												 for (NCSkillData* skill in skills) {
													 skillPoints += skill.skillPoints;
												 }
												 NSString* title = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ skillpoints)", nil),
																	[[skills[0] group] groupName],
																	[NSNumberFormatter neocomLocalizedStringFromNumber:@(skillPoints)]];
												 NCSkillsViewControllerDataSection* section = [NCSkillsViewControllerDataSection new];
												 section.title = title;
												 section.rows = skills;
												 section.group = [skills[0] group];
												 [allSkillsSections addObject:section];
											 }
											 [allSkillsSections sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
											 
											 if ([task isCancelled])
												 return;
											 
											 NSPredicate* predicate = nil;
											 
											 predicate = [NSPredicate predicateWithFormat:@"trainedLevel < 5"];
											 for (NCSkillsViewControllerDataSection* section in allSkillsSections) {
												 NSArray* canTrain = [section.rows filteredArrayUsingPredicate:predicate];
												 if (canTrain.count > 0) {
													 NCSkillsViewControllerDataSection* canTrainSection = [NCSkillsViewControllerDataSection new];
													 canTrainSection.title = section.title;
													 canTrainSection.rows = canTrain;
													 canTrainSection.group = section.group;
													 [canTrainSkillsSection addObject:canTrainSection];
												 }
											 }
											 
											 if ([task isCancelled])
												 return;
											 
											 predicate = [NSPredicate predicateWithFormat:@"trainedLevel < 0"];
											 for (NCSkillsViewControllerDataSection* section in allSkillsSections) {
												 NSArray* canTrain = [section.rows filteredArrayUsingPredicate:predicate];
												 if (canTrain.count > 0) {
													 NCSkillsViewControllerDataSection* notKnownSection = [NCSkillsViewControllerDataSection new];
													 notKnownSection.title = section.title;
													 notKnownSection.rows = canTrain;
													 notKnownSection.group = section.group;
													 [notKnownSkillsSections addObject:notKnownSection];
												 }
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.allSkillsSections = allSkillsSections;
									 self.knownSkillsSections = knownSkillsSections;
									 self.canTrainSkillsSections = canTrainSkillsSection;
									 self.notKnownSkillsSections = notKnownSkillsSections;
									 [self.tableView reloadData];
								 }
							 }];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self update];
}

- (void) didChangeStorage {
	if ([self isViewLoaded])
		[self update];
}

- (id) identifierForSection:(NSInteger)section {
	switch (self.mode) {
		case NCSkillsViewControllerModeKnownSkills:
			return @([[self.knownSkillsSections[section] group] groupID]);
		case NCSkillsViewControllerModeAllSkills:
			return @([[self.allSkillsSections[section] group] groupID]);
		case NCSkillsViewControllerModeNotKnownSkills:
			return @([[self.notKnownSkillsSections[section] group] groupID]);
		case NCSkillsViewControllerModeCanTrainSkills:
			return @([[self.canTrainSkillsSections[section] group] groupID]);
		default:
			return nil;
	}
}

- (BOOL) initiallySectionIsCollapsed:(NSInteger)section {
	return YES;
}

@end
