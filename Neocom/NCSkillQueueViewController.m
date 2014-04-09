//
//  NCSkillQueueViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 01.04.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillQueueViewController.h"
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

@interface NCSkillQueueViewController ()
@property (nonatomic, strong) NCSkillPlan* skillPlan;
@property (nonatomic, strong) NSMutableArray* skillPlanSkills;
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) NSArray* skillQueueRows;
@property (nonatomic, strong) NCCharacterAttributes* optimalAttributes;
@property (nonatomic, assign) NSTimeInterval optimalTrainingTime;
@property (nonatomic, strong) UIDocumentInteractionController* documentInteractionController;

- (IBAction)onSkills:(id)sender;

@end

@implementation NCSkillQueueViewController

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
	[self.navigationItem setRightBarButtonItems:@[self.editButtonItem,
												  [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Skills", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onSkills:)],
												  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onAction:)]]
									   animated:YES];
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
				  destructiveButtonTitle:NSLocalizedString(@"Clear Skill Plan", nil)
					   otherButtonTitles:@[NSLocalizedString(@"Import Skill Plan", nil), NSLocalizedString(@"Switch Skill Plan", nil), NSLocalizedString(@"Export Skill Plan", nil)]
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex == actionSheet.destructiveButtonIndex) {
								 [self.skillPlan clear];
								 [self.skillPlan save];
								 [self.tableView reloadData];
							 }
							 else if (selectedButtonIndex == 1) {
								 [self performSegueWithIdentifier:@"NCSkillPlanImportViewController" sender:nil];
							 }
							 else if (selectedButtonIndex == 2) {
								 [self performSegueWithIdentifier:@"NCSkillPlansViewController" sender:nil];
							 }
							 else if (selectedButtonIndex == 3) {
								 NSData* data = [[self.skillPlan.trainingQueue xmlRepresentationWithSkillPlanName:self.skillPlan.name] dataUsingEncoding:NSUTF8StringEncoding];
								 NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - %@.emp", self.account.characterInfo.characterName, self.skillPlan.name]];
								 [data writeCompressedToFile:path];
								 self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
								 [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
							 }
						 } cancelBlock:nil] showFromBarButtonItem:sender animated:YES];
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

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"trainingQueue"]) {
		if ([NSThread isMainThread]) {
			NCTrainingQueue* newQueue = change[NSKeyValueChangeNewKey];
			if (![self.skillPlanSkills isEqualToArray:newQueue.skills]) {
				self.skillPlanSkills = [[NSMutableArray alloc] initWithArray:newQueue.skills];
				[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)] withRowAnimation:UITableViewRowAnimationFade];
			}
		}
	}
	else if ([keyPath isEqualToString:@"activeSkillPlan"]) {
		if ([NSThread isMainThread]) {
			self.skillPlan = self.account.activeSkillPlan;
			[self.tableView reloadData];
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				self.skillPlan = self.account.activeSkillPlan;
				[self.tableView reloadData];
			});
		}
	}
}

- (void) dealloc {
	self.account = nil;
	self.skillPlan = nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return self.skillPlan.trainingQueue.skills.count > 0 ? 2 : 0;
	else if (section == 1)
		return self.skillQueueRows.count;
	else if (section == 2)
		return self.skillPlan.trainingQueue.skills.count;
	else
		return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			NCCharacterAttributesCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCCharacterAttributesCell"];
			[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
			return cell;
		}
		else {
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
			[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
			return cell;
		}
	}
	else {
		NCSkillCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCSkillCell"];
		[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
		return cell;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return NSLocalizedString(@"Optimal neural remap", nil);
	else if (section == 1)
		return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:[self.account.skillQueue timeLeft]], (int32_t) self.skillQueueRows.count];
	else if (section == 2) {
		if (self.skillPlan.trainingQueue.skills.count > 0)
			return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NSString stringWithTimeLeft:self.skillPlan.trainingQueue.trainingTime], (int32_t) self.skillPlan.trainingQueue.skills.count];
		else
			return NSLocalizedString(@"Skill plan is empty", nil);
	}
	else
		return nil;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 2;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 2 ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.skillPlan removeSkill:self.skillPlanSkills[indexPath.row]];
	}
}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return [self tableView:tableView canEditRowAtIndexPath:indexPath];
}

- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	id object = self.skillPlanSkills[sourceIndexPath.row];
	[self.skillPlanSkills removeObjectAtIndex:sourceIndexPath.row];
	[self.skillPlanSkills insertObject:object atIndex:destinationIndexPath.row];
	NCTrainingQueue* trainingQueue = [self.skillPlan.trainingQueue copy];
	trainingQueue.skills = self.skillPlanSkills;
	self.skillPlan.trainingQueue = trainingQueue;
	[self.skillPlan save];
}

- (NSIndexPath*) tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if (proposedDestinationIndexPath.section == 2)
		return proposedDestinationIndexPath;
	else
		return sourceIndexPath;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		if (indexPath.row == 0)
			return 76;
		else
			return 41;
	}
	else
		return 42;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		if (indexPath.row == 0)
			return 76;
		else
			return 41;
	}
	else {
		if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
			return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];

		UITableViewCell* cell = [self tableView:tableView offscreenCellWithIdentifier:@"NCSkillCell"];
		[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
		cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
		[cell setNeedsLayout];
		[cell layoutIfNeeded];
		return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (NSDate*) cacheDate {
	return self.account.skillQueue.cacheDate;
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			NCCharacterAttributesCell* cell = (NCCharacterAttributesCell*) tableViewCell;
			
			EVECharacterSheetAttributeEnhancer* charismaEnhancer = nil;
			EVECharacterSheetAttributeEnhancer* intelligenceEnhancer = nil;
			EVECharacterSheetAttributeEnhancer* memoryEnhancer = nil;
			EVECharacterSheetAttributeEnhancer* perceptionEnhancer = nil;
			EVECharacterSheetAttributeEnhancer* willpowerEnhancer = nil;
			
			EVECharacterSheet* characterSheet = self.account.characterSheet;
			for (EVECharacterSheetAttributeEnhancer *enhancer in characterSheet.attributeEnhancers) {
				switch (enhancer.attribute) {
					case EVECharacterAttributeCharisma:
						charismaEnhancer = enhancer;
						break;
					case EVECharacterAttributeIntelligence:
						intelligenceEnhancer = enhancer;
						break;
					case EVECharacterAttributeMemory:
						memoryEnhancer = enhancer;
						break;
					case EVECharacterAttributePerception:
						perceptionEnhancer = enhancer;
						break;
					case EVECharacterAttributeWillpower:
						willpowerEnhancer = enhancer;
						break;
				}
			}
			
			NSAttributedString* (^attributesString)(int32_t, EVECharacterSheetAttributeEnhancer*, int32_t) = ^(int32_t attribute, EVECharacterSheetAttributeEnhancer* enhancer, int32_t currentAttribute) {
				NSString* text;
				if (enhancer)
					text = [NSString stringWithFormat:@"%d (%d + %d)",
							attribute + enhancer.augmentatorValue,
							attribute,
							enhancer.augmentatorValue];
				else
					text = [NSString stringWithFormat:@"%d", attribute];
				
				int32_t dif = attribute - currentAttribute;
				NSString* difString;
				UIColor* color = nil;
				if (dif > 0) {
					difString = [NSString stringWithFormat:@" +%d", dif];
					color = [UIColor greenColor];
				}
				else if (dif < 0) {
					difString = [NSString stringWithFormat:@" %d", dif];
					color = [UIColor redColor];
				}
				else
					difString = @"";
				NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:[text stringByAppendingString:difString]];
				if (color)
					[s addAttributes:@{NSForegroundColorAttributeName: color} range:NSMakeRange(text.length, difString.length)];
				return s;
			};
			
			cell.intelligenceLabel.attributedText = attributesString(self.optimalAttributes.intelligence, intelligenceEnhancer, characterSheet.attributes.intelligence);
			cell.memoryLabel.attributedText = attributesString(self.optimalAttributes.memory, memoryEnhancer, characterSheet.attributes.memory);
			cell.perceptionLabel.attributedText = attributesString(self.optimalAttributes.perception, perceptionEnhancer, characterSheet.attributes.perception);
			cell.willpowerLabel.attributedText = attributesString(self.optimalAttributes.willpower, willpowerEnhancer, characterSheet.attributes.willpower);
			cell.charismaLabel.attributedText = attributesString(self.optimalAttributes.charisma, charismaEnhancer, characterSheet.attributes.charisma);
		}
		else {
			UITableViewCell* cell = tableViewCell;
			cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@", nil), [NSString stringWithTimeLeft:self.optimalTrainingTime]];
			cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ better than current", nil), [NSString stringWithTimeLeft:self.skillPlan.trainingQueue.trainingTime - self.optimalTrainingTime]];
		}
	}
	else {
		NCSkillData* row;
		
		if (indexPath.section == 1)
			row = self.skillQueueRows[indexPath.row];
		else if (indexPath.section == 2)
			row = self.skillPlan.trainingQueue.skills[indexPath.row];
		
		
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
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = self.account;
	
	if (!account) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 [account reloadWithCachePolicy:cachePolicy
																	  error:&error
															progressHandler:^(CGFloat progress, BOOL *stop) {
																task.progress = progress;
																if (task.isCancelled)
																	*stop = YES;
															}];
											 if ([task isCancelled])
												 return;
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
									 }
								 }
							 }];
}

- (void) update {
	NCAccount* account = [NCAccount currentAccount];
	self.account = account;
	self.skillPlan = account.activeSkillPlan;

	[super update];
	
	[self.account.characterSheet updateSkillPointsFromSkillQueue:self.account.skillQueue];
	[self.skillPlan updateSkillPoints];
	
	NSMutableArray* skillQueueRows = [NSMutableArray new];
	
	EVESkillQueue* skillQueue = self.account.skillQueue;
	EVECharacterSheet* characterSheet = self.account.characterSheet;
	NCCharacterAttributes* characterAttributes = self.account.characterAttributes;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 for (EVESkillQueueItem *item in skillQueue.skillQueue) {
												 NCSkillData* skillData = [[NCSkillData alloc] initWithTypeID:item.typeID error:nil];
												 if (!skillData)
													 continue;
												 EVECharacterSheetSkill* characterSheetSkill = characterSheet.skillsMap[@(item.typeID)];

												 skillData.targetLevel = item.level;
												 skillData.currentLevel = item.level - 1;
												 skillData.skillPoints = characterSheetSkill.skillpoints;
												 skillData.trainedLevel = characterSheetSkill.level;
												 skillData.active = item.queuePosition == 0;
												 skillData.characterAttributes = characterAttributes;
												 [skillQueueRows addObject:skillData];
											 }
											 
											 if ([task isCancelled])
												 return;
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.skillQueueRows = skillQueueRows;
									 [self.tableView reloadData];
								 }
							 }];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self update];
}

- (id) identifierForSection:(NSInteger)section {
	return @(section);
}

#pragma mark - Unwind

- (IBAction)unwindFromSkillPlanImport:(UIStoryboardSegue*) segue {
	
}

#pragma mark - Private

- (void) setSkillPlan:(NCSkillPlan *)skillPlan {
	[_skillPlan removeObserver:self forKeyPath:@"trainingQueue"];
	_skillPlan = skillPlan;
	self.skillPlanSkills = [[NSMutableArray alloc] initWithArray:skillPlan.trainingQueue.skills];
	[_skillPlan addObserver:self forKeyPath:@"trainingQueue" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void) setAccount:(NCAccount *)account {
	[_account removeObserver:self forKeyPath:@"activeSkillPlan"];
	_account = account;
	[_account addObserver:self forKeyPath:@"activeSkillPlan" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void) setSkillPlanSkills:(NSMutableArray *)skillPlanSkills {
	_skillPlanSkills = skillPlanSkills;
	_optimalAttributes = [NCCharacterAttributes optimalAttributesWithTrainingQueue:self.skillPlan.trainingQueue];
	EVECharacterSheet* characterSheet = self.account.characterSheet;
	
	NCCharacterAttributes* optimalAttributes = [NCCharacterAttributes new];
	optimalAttributes.charisma = _optimalAttributes.charisma;
	optimalAttributes.intelligence = _optimalAttributes.intelligence;
	optimalAttributes.memory = _optimalAttributes.memory;
	optimalAttributes.perception = _optimalAttributes.perception;
	optimalAttributes.willpower = _optimalAttributes.willpower;
	
	if (characterSheet) {
		
		for (EVECharacterSheetAttributeEnhancer *enhancer in characterSheet.attributeEnhancers) {
			switch (enhancer.attribute) {
				case EVECharacterAttributeCharisma:
					optimalAttributes.charisma += enhancer.augmentatorValue;
					break;
				case EVECharacterAttributeIntelligence:
					optimalAttributes.intelligence += enhancer.augmentatorValue;
					break;
				case EVECharacterAttributeMemory:
					optimalAttributes.memory += enhancer.augmentatorValue;
					break;
				case EVECharacterAttributePerception:
					optimalAttributes.perception += enhancer.augmentatorValue;
					break;
				case EVECharacterAttributeWillpower:
					optimalAttributes.willpower += enhancer.augmentatorValue;
					break;
			}
		}
	}
	_optimalTrainingTime = [self.skillPlan.trainingQueue trainingTimeWithCharacterAttributes:optimalAttributes];
}

- (IBAction)onSkills:(id)sender {
	[self performSegueWithIdentifier:@"NCSkillsViewController" sender:nil];
}

@end
