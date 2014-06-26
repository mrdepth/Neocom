//
//  NCFittingCharacterEditorViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingCharacterEditorViewController.h"
#import "NCFitCharacter.h"
#import "NSArray+Neocom.h"
#import "UIActionSheet+Block.h"
#import "NCFittingCharacterEditorCell.h"
#import "UIAlertView+Block.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NSString+Neocom.h"

@interface NCFittingCharacterEditorViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSDictionary* skills;
@end

@implementation NCFittingCharacterEditorViewController

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
	self.refreshControl = nil;
	self.title = self.character.name;

	NSMutableDictionary* skills = [NSMutableDictionary new];
	NSMutableArray* sections = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCDatabase* database = [NCDatabase sharedDatabase];
											 [database.backgroundManagedObjectContext performBlockAndWait:^{
												 NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
												 request.predicate = [NSPredicate predicateWithFormat:@"published == TRUE AND group.category.categoryID == 16"];
												 request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"group.groupName" ascending:YES],
																			 [NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
												 NSFetchedResultsController* result = [[NSFetchedResultsController alloc] initWithFetchRequest:request
																														  managedObjectContext:database.backgroundManagedObjectContext
																															sectionNameKeyPath:@"group.groupName"
																																	 cacheName:nil];
												 [result performFetch:nil];
												 for (id<NSFetchedResultsSectionInfo> sectionInfo in result.sections) {
													 NCDBInvGroup* group = nil;
													 
													 NSMutableArray* rows = [NSMutableArray new];
													 for (NCDBInvType* type in sectionInfo.objects) {
														 if (!group)
															 group = type.group;
														 NCSkillData* skillData = [[NCSkillData alloc] initWithInvType:type];
														 [rows addObject:skillData];
														 skills[@(type.typeID)] = skillData;
													 }
													 [sections addObject:@{@"title": sectionInfo.name, @"rows": rows, @"sectionID": @(group.groupID)}];
												 }
											 }];
											 [self.character.skills enumerateKeysAndObjectsUsingBlock:^(NSNumber* typeID, NSNumber* level, BOOL *stop) {
												 NCSkillData* skillData = skills[typeID];
												 skillData.currentLevel = [level intValue];
											 }];

										 }
							 completionHandler:^(NCTask *task) {
								 self.skills = skills;
								 self.sections = sections;
								 [self update];
							 }];
	// Do any additional setup after loading the view.
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	NSMutableDictionary* skills = [NSMutableDictionary new];
	[self.skills enumerateKeysAndObjectsUsingBlock:^(NSNumber* typeID, NCSkillData* skillData, BOOL *stop) {
		skills[typeID] = @(skillData.currentLevel);
	}];
	self.character.skills = skills;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onAction:(id)sender {
	NCAccount* account = [NCAccount currentAccount];
	NCSkillPlan* activeSkillPlan = account.activeSkillPlan;
	NSArray* otherButtonTitles = activeSkillPlan ? @[NSLocalizedString(@"Rename", nil),
													 NSLocalizedString(@"Add to active Skill Plan", nil),
													 NSLocalizedString(@"Import from active Skill Plan", nil)] : @[NSLocalizedString(@"Rename", nil)];

	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:otherButtonTitles
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 if (selectedButtonIndex == 0) {
									 UIAlertView* alertView = [UIAlertView alertViewWithTitle:NSLocalizedString(@"Rename", nil)
																					  message:nil
																			cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
																			otherButtonTitles:@[NSLocalizedString(@"Rename", nil)]
																			  completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
																				  if (selectedButtonIndex != alertView.cancelButtonIndex) {
																					  UITextField* textField = [alertView textFieldAtIndex:0];
																					  self.character.name = textField.text;
																					  self.title = self.character.name;
																				  }
																			  } cancelBlock:nil];
									 alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
									 UITextField* textField = [alertView textFieldAtIndex:0];
									 textField.text = self.character.name;
									 [alertView show];
								 }
								 else if (selectedButtonIndex == 1){
									 NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:account];
									 [self.skills enumerateKeysAndObjectsUsingBlock:^(NSNumber* typeID, NCSkillData* skillData, BOOL *stop) {
										 [trainingQueue addSkill:skillData.type withLevel:skillData.currentLevel];
									 }];
									 
									 [[UIAlertView alertViewWithTitle:NSLocalizedString(@"Add to skill plan?", nil)
															  message:[NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:trainingQueue.trainingTime]]
													cancelButtonTitle:NSLocalizedString(@"No", nil)
													otherButtonTitles:@[NSLocalizedString(@"Yes", nil)]
													  completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
														  if (selectedButtonIndex != alertView.cancelButtonIndex) {
															  [activeSkillPlan mergeWithTrainingQueue:trainingQueue];
														  }
													  }
														  cancelBlock:nil] show];

								 }
								 else {
									 [[UIAlertView alertViewWithTitle:nil
															  message:NSLocalizedString(@"Your skill levels will be replaced with values from skill plan", nil)
													cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
													otherButtonTitles:@[NSLocalizedString(@"Import", nil)]
													  completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
														  if (selectedButtonIndex != alertView.cancelButtonIndex) {
															  [self.skills enumerateKeysAndObjectsUsingBlock:^(NSNumber* typeID, NCSkillData* skillData, BOOL *stop) {
																  skillData.currentLevel = 0;
															  }];
														  }
														  for (EVECharacterSheetSkill* characterSkill in account.characterSheet.skills) {
															  NCSkillData* skill = self.skills[@(characterSkill.typeID)];
															  skill.currentLevel = MAX(skill.currentLevel, characterSkill.level);
														  }
														  for (NCSkillData* skillPlanSkill in activeSkillPlan.trainingQueue.skills) {
															  NCSkillData* skill = self.skills[@(skillPlanSkill.type.typeID)];
															  skill.currentLevel = MAX(skill.currentLevel, skillPlanSkill.targetLevel);
														  }
														  [self.tableView reloadData];
													  }
														  cancelBlock:nil] show];
								 }
							 }
						 }
							 cancelBlock:nil] showFromBarButtonItem:sender animated:YES];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.type = [sender skillData];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section][@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingCharacterEditorCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 37;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView offscreenCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCSkillData* skill = self.sections[indexPath.section][@"rows"][indexPath.row];
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	NSMutableArray* buttons = [NSMutableArray new];
	for (int i = 0; i <=5; i++)
		[buttons addObject:[NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), i]];
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 skill.currentLevel = (int32_t) selectedButtonIndex;
								 [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
							 }
						 }
							 cancelBlock:^{
								 
							 }] showFromRect:cell.bounds inView:cell animated:YES];
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (id) identifierForSection:(NSInteger)section {
	return self.sections[section][@"sectionID"];
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingCharacterEditorCell* cell = (NCFittingCharacterEditorCell*) tableViewCell;
	NCSkillData* skill = self.sections[indexPath.section][@"rows"][indexPath.row];
	
	cell.skillNameLabel.text = skill.type.typeName;
	cell.skillLevelLabel.text = [NSString stringWithFormat:@"%d", skill.currentLevel];
	cell.skillData = skill;
}

@end
