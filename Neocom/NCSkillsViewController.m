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

@interface NCSkillsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NCCharacterAttributes* characterAttributes;
@property (nonatomic, strong) EVECharacterSheet* characterSheet;
@property (nonatomic, strong) EVESkillQueue* skillQueue;

@end

@interface NCSkillsViewController ()
@property (nonatomic, strong) NCSkillPlan* skillPlan;
@property (nonatomic, strong) NSMutableArray* skillPlanSkills;
@property (nonatomic, strong) NCAccount* account;

@property (nonatomic, strong) NSArray* skillQueueRows;
@property (nonatomic, strong) NSArray* allSkillsSections;
@property (nonatomic, strong) NSArray* knownSkillsSections;
@property (nonatomic, strong) NSArray* notKnownSkillsSections;
@property (nonatomic, strong) NSArray* canTrainSkillsSections;

@property (nonatomic, strong) NCCharacterAttributes* optimalAttributes;
@property (nonatomic, assign) NSTimeInterval optimalTrainingTime;

@property (nonatomic, strong) UIDocumentInteractionController* documentInteractionController;

@end

@implementation NCSkillsViewControllerDataSection;

@end

@implementation NCSkillsViewControllerData

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.characterSheet)
		[aCoder encodeObject:self.characterSheet forKey:@"characterSheet"];
	if (self.characterAttributes)
		[aCoder encodeObject:self.characterAttributes forKey:@"characterAttributes"];
	if (self.skillQueue)
		[aCoder encodeObject:self.skillQueue forKey:@"skillQueue"];
	
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.characterSheet = [aDecoder decodeObjectForKey:@"characterSheet"];
		self.characterAttributes = [aDecoder decodeObjectForKey:@"characterAttributes"];
		self.skillQueue = [aDecoder decodeObjectForKey:@"skillQueue"];
	}
	return self;
}

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
	[self.navigationItem setRightBarButtonItems:@[self.editButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onAction:)]]
									   animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onChangeMode:(id)sender {
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:@[NSLocalizedString(@"Skill Queue", nil), NSLocalizedString(@"My Skills", nil), NSLocalizedString(@"All Skills", nil), NSLocalizedString(@"Not Known", nil), NSLocalizedString(@"Can Train", nil)]
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex == actionSheet.cancelButtonIndex)
								 return;
							 UIButton* button = (UIButton*) self.navigationItem.titleView;
							 
							 [button setTitle:[actionSheet buttonTitleAtIndex:selectedButtonIndex] forState:UIControlStateNormal];
							 [button setTitle:[actionSheet buttonTitleAtIndex:selectedButtonIndex] forState:UIControlStateHighlighted];
							 switch (selectedButtonIndex) {
								 case 0:
									 self.mode = NCSkillsViewControllerModeTrainingQueue;
									 [self.navigationItem setRightBarButtonItems:@[self.editButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onAction:)]]
																		animated:YES];
									 break;
								 case 1:
									 self.mode = NCSkillsViewControllerModeKnownSkills;
									 [self.navigationItem setRightBarButtonItems:nil animated:YES];
									 break;
								 case 2:
									 self.mode = NCSkillsViewControllerModeAllSkills;
									 [self.navigationItem setRightBarButtonItems:nil animated:YES];
									 break;
								 case 3:
									 self.mode = NCSkillsViewControllerModeNotKnownSkills;
									 [self.navigationItem setRightBarButtonItems:nil animated:YES];
									 break;
								 case 4:
									 self.mode = NCSkillsViewControllerModeCanTrainSkills;
									 [self.navigationItem setRightBarButtonItems:nil animated:YES];
									 break;
								 default:
									 break;
							 }
							 [self.tableView reloadData];
						 } cancelBlock:nil] showFromRect:[sender bounds] inView:sender animated:YES];
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
/*								 SkillPlannerImportViewController* controller = [[SkillPlannerImportViewController alloc] initWithNibName:@"SkillPlannerImportViewController" bundle:nil];
								 controller.delegate = self;
								 UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
								 navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
								 
								 if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
									 navController.modalPresentationStyle = UIModalPresentationFormSheet;
								 [self presentViewController:navController animated:YES completion:nil];*/
							 }
							 else if (selectedButtonIndex == 2) {
								 [self performSegueWithIdentifier:@"NCSkillPlansViewController" sender:nil];
							 }
							 else if (selectedButtonIndex == 3) {
								 NSData* data = [[self.skillPlan.trainingQueue xmlRepresentationWithSkillPlanName:self.skillPlan.name] dataUsingEncoding:NSUTF8StringEncoding];
								 NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.emp", self.skillPlan.name]];
								 [data writeCompressedToFile:path];
								 self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
								 [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
							 }
						 } cancelBlock:nil] showFromBarButtonItem:sender animated:YES];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.type = [sender skillData];
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"trainingQueue"]) {
		if ([NSThread isMainThread]) {
			NCTrainingQueue* new = change[NSKeyValueChangeNewKey];
			self.skillPlanSkills = [[NSMutableArray alloc] initWithArray:new.skills];
			
			if (self.mode == NCSkillsViewControllerModeTrainingQueue) {
				[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)] withRowAnimation:UITableViewRowAnimationFade];
			}
		}
	}
	else if ([keyPath isEqualToString:@"activeSkillPlan"]) {
		if ([NSThread isMainThread]) {
			self.skillPlan = self.account.activeSkillPlan;
			if (self.mode == NCSkillsViewControllerModeTrainingQueue) {
				[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)] withRowAnimation:UITableViewRowAnimationFade];
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				self.skillPlan = self.account.activeSkillPlan;
				if (self.mode == NCSkillsViewControllerModeTrainingQueue) {
					[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)] withRowAnimation:UITableViewRowAnimationFade];
				}
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
	switch (self.mode) {
		case NCSkillsViewControllerModeTrainingQueue:
			return 3;
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
		case NCSkillsViewControllerModeTrainingQueue: {
			if (section == 0)
				return self.skillQueueRows.count;
			else if (section == 1)
				return self.skillPlan.trainingQueue.skills.count;
			else
				return self.skillPlan.trainingQueue.skills.count > 0 ? 2 : 0;
		}
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
	if (self.mode == NCSkillsViewControllerModeTrainingQueue && indexPath.section == 2) {
		if (indexPath.row == 0) {
			NCCharacterAttributesCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCCharacterAttributesCell"];
			
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
			
			NSInteger intelligenceDiff = characterSheet.attributes.intelligence - self.optimalAttributes.intelligence;
			NSInteger memoryDiff = characterSheet.attributes.memory - self.optimalAttributes.memory;
			NSInteger perceptionDiff = characterSheet.attributes.perception - self.optimalAttributes.perception;
			NSInteger willpowerDiff = characterSheet.attributes.willpower - self.optimalAttributes.willpower;
			NSInteger charismaDiff = characterSheet.attributes.charisma - self.optimalAttributes.charisma;
			
			NSAttributedString* (^attributesString)(NSInteger, EVECharacterSheetAttributeEnhancer*, NSInteger) = ^(NSInteger attribute, EVECharacterSheetAttributeEnhancer* enhancer, NSInteger currentAttribute) {
				NSString* text;
				if (enhancer)
					text = [NSString stringWithFormat:@"%d (%d + %d)",
							attribute + enhancer.augmentatorValue,
							attribute,
							enhancer.augmentatorValue];
				else
					text = [NSString stringWithFormat:@"%d", attribute];
				
				NSInteger dif = attribute - currentAttribute;
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
			return cell;
		}
		else {
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
			cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@", nil), [NSString stringWithTimeLeft:self.optimalTrainingTime]];
			cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ better than current", nil), [NSString stringWithTimeLeft:self.skillPlan.trainingQueue.trainingTime - self.optimalTrainingTime]];
			return cell;
		}
	}
	
	NCSkillData* row;
	
	NCSkillsViewControllerData* data = self.data;
	switch (self.mode) {
		case NCSkillsViewControllerModeTrainingQueue:
			row = indexPath.section == 0 ? self.skillQueueRows[indexPath.row] : self.skillPlan.trainingQueue.skills[indexPath.row];
			break;
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
	
	
	NCSkillCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCSkillCell" forIndexPath:indexPath];
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
									  [NSNumberFormatter neocomLocalizedStringFromNumber:@([data.characterAttributes skillpointsPerSecondForSkill:row] * 3600)]];
		cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), MAX(row.targetLevel, row.trainedLevel)];
		[cell.levelImageView setGIFImageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"level_%d%d%d", row.trainedLevel, row.targetLevel, row.active] withExtension:@"gif"]];
		cell.dateLabel.text = row.trainingTimeToLevelUp > 0 ? [NSString stringWithFormat:@"%@ (%.0f%%)", [NSString stringWithTimeLeft:row.trainingTimeToLevelUp], progress * 100] : nil;
	}
	else {
		cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ SP/h", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@([data.characterAttributes skillpointsPerSecondForSkill:row] * 3600)]];
		cell.levelLabel.text = nil;
		cell.levelImageView.image = nil;
		cell.dateLabel.text = nil;
	}
	cell.titleLabel.text = row.skillName;

	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NCSkillsViewControllerData* data = self.data;
	switch (self.mode) {
		case NCSkillsViewControllerModeTrainingQueue:
			if (section == 0)
				return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:[data.skillQueue timeLeft]], self.skillQueueRows.count];
			else if (section == 1) {
				if (self.skillPlan.trainingQueue.skills.count > 0)
					return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NSString stringWithTimeLeft:self.skillPlan.trainingQueue.trainingTime], self.skillPlan.trainingQueue.skills.count];
				else
					return NSLocalizedString(@"Skill plan is empty", nil);
			}
			else
				return NSLocalizedString(@"Optimal neural remap", nil);
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

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.mode == NCSkillsViewControllerModeTrainingQueue && indexPath.section == 1;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.mode == NCSkillsViewControllerModeTrainingQueue && indexPath.section == 1 ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
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

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.mode == NCSkillsViewControllerModeTrainingQueue && indexPath.section == 2) {
		if (indexPath.row == 0)
			return 76;
		else
			return 44;
	}
	else
		return 42;
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	
	if (!account) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	
	NCSkillsViewControllerData* data = [NCSkillsViewControllerData new];
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
											 data.characterSheet = account.characterSheet;
											 data.skillQueue = account.skillQueue;
											 data.characterAttributes = account.characterAttributes;
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:data withCacheDate:data.skillQueue.cacheDate expireDate:data.skillQueue.cacheExpireDate];
									 }
								 }
							 }];
}

- (void) update {
	NCAccount* account = [NCAccount currentAccount];
	self.account = account;
	self.skillPlan = account.activeSkillPlan;
	
	NCSkillsViewControllerData* data = self.data;
	
	[super update];
	
	[data.characterSheet updateSkillPointsFromSkillQueue:data.skillQueue];
	[account.characterSheet updateSkillPointsFromSkillQueue:account.skillQueue];
	[self.skillPlan updateSkillPoints];

	
	NSMutableArray* skillQueueRows = [NSMutableArray new];
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

											 for (EVECharacterSheetSkill* characterSheetSkill in data.characterSheet.skills) {
												 NCSkillData* skillData = allSkills[@(characterSheetSkill.typeID)];
												 if (skillData) {
													 skillData.trainedLevel = characterSheetSkill.level;
													 skillData.skillPoints = characterSheetSkill.skillpoints;
													 skillData.characterAttributes = data.characterAttributes;
													 [knownSkills addObject:skillData];
												 }
											 }
											 if ([task isCancelled])
												 return;
											 
											 [knownSkills sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
											 
											 for (EVESkillQueueItem *item in data.skillQueue.skillQueue) {
												 NCSkillData* skillData = allSkills[@(item.typeID)];
												 if (!skillData)
													 continue;
												 
												 skillData.targetLevel = MAX(skillData.targetLevel, item.level);
												 if (item.queuePosition == 0)
													 skillData.active = YES;
												 
												 NCSkillData* queueSkillData = [[NCSkillData alloc] initWithInvType:skillData];
												 queueSkillData.targetLevel = item.level;
												 queueSkillData.currentLevel = item.level - 1;
												 queueSkillData.skillPoints = skillData.skillPoints;
												 queueSkillData.trainedLevel = skillData.trainedLevel;
												 queueSkillData.active = skillData.active;
												 queueSkillData.characterAttributes = data.characterAttributes;
												 [skillQueueRows addObject:queueSkillData];
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
											 
											 predicate = [NSPredicate predicateWithFormat:@"trainedLevel < 5 AND trainedLevel >= 0"];
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
									 self.skillQueueRows = skillQueueRows;
									 [self.tableView reloadData];
								 }
							 }];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}

- (NSDate*) cacheDate {
	NCAccount* account = [NCAccount currentAccount];
	return account.characterSheet.cacheDate;
}

- (id) identifierForSection:(NSInteger)section {
	switch (self.mode) {
		case NCSkillsViewControllerModeTrainingQueue:
			return @(section);
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
	if (self.mode == NCSkillsViewControllerModeTrainingQueue)
		return NO;
	else
		return YES;
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

@end
