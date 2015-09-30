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
#import "NCDefaultTableViewCell.h"

@interface NCSkillQueueViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) EVESkillQueue* skillQueue;
@property (nonatomic, strong) EVECharacterSheet* characterSheet;
@property (nonatomic, strong) NCCharacterAttributes* characterAttributes;
@end

@implementation NCSkillQueueViewControllerData

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.skillQueue = [aDecoder decodeObjectForKey:@"skillQueue"];
		self.characterSheet = [aDecoder decodeObjectForKey:@"characterSheet"];
		self.characterAttributes = [aDecoder decodeObjectForKey:@"characterAttributes"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.skillQueue forKey:@"skillQueue"];
	[aCoder encodeObject:self.characterSheet forKey:@"characterSheet"];
	[aCoder encodeObject:self.characterAttributes forKey:@"characterAttributes"];
}

@end

@interface NCSkillQueueViewController ()
@property (nonatomic, strong) NCSkillPlan* skillPlan;
@property (nonatomic, strong) NSString* skillPlanName;
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) NSArray* skillQueueRows;
@property (nonatomic, strong) NCCharacterAttributes* optimalAttributes;
@property (nonatomic, assign) NSTimeInterval optimalTrainingTime;
@property (nonatomic, strong) UIDocumentInteractionController* documentInteractionController;
@property (nonatomic, strong) NCTrainingQueue* fullTrainingQueue;
@property (nonatomic, strong) NCTrainingQueue* skillPlanTrainingQueue;
@property (nonatomic, strong) NSMutableDictionary* types;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;

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
	self.types = [NSMutableDictionary new];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	self.account = [NCAccount currentAccount];
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
								 [self.account loadCharacterInfoWithCompletionBlock:^(EVECharacterInfo *characterInfo, NSError *error) {
									 dispatch_async(dispatch_get_main_queue(), ^{
										 NSData* data = [[self.skillPlanTrainingQueue xmlRepresentationWithSkillPlanName:self.skillPlanName] dataUsingEncoding:NSUTF8StringEncoding];
										 NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - %@.emp", characterInfo.characterName, self.skillPlanName]];
										 [data writeCompressedToFile:path];
										 self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
										 [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
									 });
								 }];
							 }
						 } cancelBlock:nil] showFromBarButtonItem:sender animated:YES];
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

/*- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"trainingQueue"]) {
		if ([NSThread isMainThread]) {
			NCTrainingQueue* newQueue = change[NSKeyValueChangeNewKey];
			if (![self.skillPlanTrainingQueue.skills isEqualToArray:newQueue.skills]) {
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
}*/

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
		return 2;//self.skillPlan.trainingQueue.skills.count > 0 ? 2 : 0;
	else if (section == 1)
		return self.skillQueueRows.count;
	else if (section == 2)
		return self.skillPlanTrainingQueue.skills.count;
	else
		return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NCSkillQueueViewControllerData* data = self.cacheData;
	if (section == 0)
		return NSLocalizedString(@"Optimal neural remap", nil);
	else if (section == 1)
		return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:[data.skillQueue timeLeft]], (int32_t) self.skillQueueRows.count];
	else if (section == 2) {
		if (self.skillPlanTrainingQueue.skills.count > 0)
			return [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills) in %@", nil),
					[NSString stringWithTimeLeft:self.skillPlanTrainingQueue.trainingTime],
					(int32_t) self.skillPlanTrainingQueue.skills.count,
					self.skillPlanName.length > 0 ? self.skillPlanName : NSLocalizedString(@"<noname>", nil)];
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
		[self.skillPlanTrainingQueue removeSkill:self.skillPlanTrainingQueue.skills[indexPath.row]];
		[self.skillPlan save];
	}
}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return [self tableView:tableView canEditRowAtIndexPath:indexPath];
}

- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	[self.skillPlanTrainingQueue moveSkillAdIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
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
	if (indexPath.section == 0 && indexPath.row == 0)
		return 73;
	else
		return self.tableView.rowHeight;
}

#pragma mark - NCTableViewController

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		if (indexPath.row == 0)
			return @"NCCharacterAttributesCell";
		else
			return @"Cell";
	}
	else {
		NCSkillData* row;
		
		if (indexPath.section == 1)
			row = self.skillQueueRows[indexPath.row];
		else if (indexPath.section == 2)
			row = self.skillPlanTrainingQueue.skills[indexPath.row];
		
		if (row.trainedLevel >= 0)
			return @"NCSkillCell";
		else
			return @"NCSkillCompactCell";
	}
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCSkillQueueViewControllerData* data = self.cacheData;
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			NCCharacterAttributesCell* cell = (NCCharacterAttributesCell*) tableViewCell;
			EVECharacterSheet* characterSheet = data.characterSheet;

			NCDBInvType* charismaEnhancer = nil;
			NCDBInvType* intelligenceEnhancer = nil;
			NCDBInvType* memoryEnhancer = nil;
			NCDBInvType* perceptionEnhancer = nil;
			NCDBInvType* willpowerEnhancer = nil;
			
			for (EVECharacterSheetImplant* implant in characterSheet.implants) {
				NCDBInvType* type = self.types[@(implant.typeID)];
				if (!type) {
					type = [self.databaseManagedObjectContext invTypeWithTypeID:implant.typeID];
					if (type)
						self.types[@(implant.typeID)] = type;
				}
				
				if ([(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCCharismaBonusAttributeID)] value] > 0)
					charismaEnhancer = type;
				else if ([(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCIntelligenceBonusAttributeID)] value] > 0)
					intelligenceEnhancer = type;
				else if ([(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCMemoryBonusAttributeID)] value] > 0)
					memoryEnhancer = type;
				else if ([(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCPerceptionBonusAttributeID)] value] > 0)
					perceptionEnhancer = type;
				else if ([(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCWillpowerBonusAttributeID)] value] > 0)
					willpowerEnhancer = type;
			}

			
			NSAttributedString* (^attributesString)(int32_t, int32_t, int32_t) = ^(int32_t attribute, int32_t enhancer, int32_t currentAttribute) {
				NSString* text;
				if (enhancer > 0)
					text = [NSString stringWithFormat:@"%d (%d + %d)",
							attribute + enhancer,
							attribute,
							enhancer];
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
					color = [UIColor yellowColor];
				}
				else
					difString = @"";
				NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:[text stringByAppendingString:difString]];
				if (color)
					[s addAttributes:@{NSForegroundColorAttributeName: color} range:NSMakeRange(text.length, difString.length)];
				return s;
			};
			
			cell.intelligenceLabel.attributedText = attributesString(self.optimalAttributes.intelligence, [(NCDBDgmTypeAttribute*) intelligenceEnhancer.attributesDictionary[@(NCIntelligenceBonusAttributeID)] value], characterSheet.attributes.intelligence);
			cell.memoryLabel.attributedText = attributesString(self.optimalAttributes.memory, [(NCDBDgmTypeAttribute*) memoryEnhancer.attributesDictionary[@(NCMemoryBonusAttributeID)] value], characterSheet.attributes.memory);
			cell.perceptionLabel.attributedText = attributesString(self.optimalAttributes.perception, [(NCDBDgmTypeAttribute*) perceptionEnhancer.attributesDictionary[@(NCPerceptionBonusAttributeID)] value], characterSheet.attributes.perception);
			cell.willpowerLabel.attributedText = attributesString(self.optimalAttributes.willpower, [(NCDBDgmTypeAttribute*) willpowerEnhancer.attributesDictionary[@(NCWillpowerBonusAttributeID)] value], characterSheet.attributes.willpower);
			cell.charismaLabel.attributedText = attributesString(self.optimalAttributes.charisma, [(NCDBDgmTypeAttribute*) charismaEnhancer.attributesDictionary[@(NCCharismaBonusAttributeID)] value], characterSheet.attributes.charisma);
		}
		else {
			NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
			cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@", nil), [NSString stringWithTimeLeft:self.optimalTrainingTime]];
			cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ better than current", nil), [NSString stringWithTimeLeft:self.fullTrainingQueue.trainingTime - self.optimalTrainingTime]];
		}
	}
	else {
		NCSkillData* row;
		if (indexPath.section == 1)
			row = self.skillQueueRows[indexPath.row];
		else if (indexPath.section == 2)
			row = self.skillPlanTrainingQueue.skills[indexPath.row];
		
		
		NCSkillCell* cell = (NCSkillCell*) tableViewCell;
		cell.skillData = row;
		
		NCDBInvType* type = self.types[@(row.typeID)];
		if (!type) {
			type = [self.databaseManagedObjectContext invTypeWithTypeID:row.typeID];
			if (type)
				self.types[@(row.typeID)] = type;
		}
		
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
										  [NSNumberFormatter neocomLocalizedStringFromNumber:@([data.characterAttributes skillpointsPerSecondForSkill:type] * 3600)]];
			cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), MAX(row.targetLevel, row.trainedLevel)];
			[cell.levelImageView setGIFImageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"level_%d%d%d", row.trainedLevel, row.targetLevel, row.active] withExtension:@"gif"]];
			cell.dateLabel.text = row.trainingTimeToLevelUp > 0 ? [NSString stringWithFormat:@"%@ (%.0f%%)", [NSString stringWithTimeLeft:row.trainingTimeToLevelUp], progress * 100] : nil;
		}
		else {
			cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ SP/h", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@([data.characterAttributes skillpointsPerSecondForSkill:type] * 3600)]];
			cell.levelLabel.text = nil;
			cell.levelImageView.image = nil;
			cell.dateLabel.text = nil;
		}
		cell.titleLabel.text = row.description;
	}
}

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock progressBlock:(void (^)(float))progressBlock {
	__block NSError* lastError = nil;
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:3];
	
	[account.managedObjectContext performBlock:^{
		if (account.accountType == NCAccountTypeCharacter) {
			[account reloadWithCachePolicy:cachePolicy completionBlock:^(NSError *error) {
				if (error)
					lastError = error;
				@synchronized(progress) {
					progress.completedUnitCount++;
				}
				NCSkillQueueViewControllerData* data = [NCSkillQueueViewControllerData new];
				
				dispatch_group_t finishDispatchGroup = dispatch_group_create();

				dispatch_group_enter(finishDispatchGroup);
				[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
					if (error)
						lastError = error;
					data.characterSheet = characterSheet;
					data.characterAttributes = [[NCCharacterAttributes alloc] initWithCharacterSheet:characterSheet];
					dispatch_group_leave(finishDispatchGroup);
					@synchronized(progress) {
						progress.completedUnitCount++;
					}
				}];
				
				dispatch_group_enter(finishDispatchGroup);
				[account loadSkillQueueWithCompletionBlock:^(EVESkillQueue *skillQueue, NSError *error) {
					if (error)
						lastError = error;
					data.skillQueue = skillQueue;
					dispatch_group_leave(finishDispatchGroup);
					@synchronized(progress) {
						progress.completedUnitCount++;
					}
				}];
				
				dispatch_group_notify(finishDispatchGroup, dispatch_get_main_queue(), ^{
					if (data.skillQueue)
						[data.characterSheet attachSkillQueue:data.skillQueue];
					
					[self saveCacheData:data cacheDate:[data.skillQueue.eveapi localTimeWithServerTime:data.skillQueue.eveapi.cacheDate] expireDate:[data.skillQueue.eveapi localTimeWithServerTime:data.skillQueue.eveapi.cachedUntil]];
					completionBlock(lastError);
				});
			} progressBlock:nil];
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(nil);
			});
		}
	}];
}

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCAccount* account = self.account;
	if (account) {
		NCSkillQueueViewControllerData* data = cacheData;
		
		dispatch_group_t finishDispatchGroup = dispatch_group_create();
		
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		NSMutableArray* skillQueueRows = [NSMutableArray new];
		dispatch_group_enter(finishDispatchGroup);
		[databaseManagedObjectContext performBlock:^{
			for (EVESkillQueueItem *item in data.skillQueue.skillQueue) {
				NCDBInvType* type = [databaseManagedObjectContext invTypeWithTypeID:item.typeID];
				if (!type)
					continue;
				
				NCSkillData* skillData = [[NCSkillData alloc] initWithInvType:type];
				skillData.targetLevel = item.level;
				skillData.currentLevel = item.level - 1;
				skillData.characterSkill = data.characterSheet.skillsMap[@(item.typeID)];
				skillData.characterAttributes = data.characterAttributes;
				[skillQueueRows addObject:skillData];
			}
			dispatch_group_leave(finishDispatchGroup);
		}];

		__block NSString* skillPlanName;
		__block NCTrainingQueue* trainingQueue;
		__block NCSkillPlan* activeSkillPlan;
		dispatch_group_enter(finishDispatchGroup);
		[account.managedObjectContext performBlock:^{
			activeSkillPlan = account.activeSkillPlan;
			skillPlanName = activeSkillPlan.name;
			[activeSkillPlan loadTrainingQueueWithCompletionBlock:^(NCTrainingQueue *result) {
				trainingQueue = result;
				dispatch_group_leave(finishDispatchGroup);
			}];
		}];
		
		dispatch_group_notify(finishDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			[trainingQueue.databaseManagedObjectContext performBlock:^{
				NCTrainingQueue* fullTrainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:data.characterSheet databaseManagedObjectContext:trainingQueue.databaseManagedObjectContext];
				NSMutableDictionary* types = [NSMutableDictionary new];
				for (NCSkillData* skillData in trainingQueue.skills ? [skillQueueRows arrayByAddingObjectsFromArray:trainingQueue.skills] : skillQueueRows) {
					NCDBInvType* type = types[@(skillData.typeID)];
					if (!type) {
						type = [trainingQueue.databaseManagedObjectContext invTypeWithTypeID:skillData.typeID];
						if (type)
							types[@(skillData.typeID)] = type;
						else
							continue;
					}
					[fullTrainingQueue addSkill:type withLevel:skillData.targetLevel];
				}
				
				NCCharacterAttributes* optimalAttributes = [NCCharacterAttributes optimalAttributesWithTrainingQueue:fullTrainingQueue];
				
				NCCharacterAttributes* finalAttributes = [NCCharacterAttributes new];
				finalAttributes.charisma = optimalAttributes.charisma;
				finalAttributes.intelligence = optimalAttributes.intelligence;
				finalAttributes.memory = optimalAttributes.memory;
				finalAttributes.perception = optimalAttributes.perception;
				finalAttributes.willpower = optimalAttributes.willpower;
				
				if (data.characterSheet) {
					
					for (EVECharacterSheetImplant* implant in data.characterSheet.implants) {
						NCDBInvType* type = types[@(implant.typeID)];
						if (!type) {
							type = [trainingQueue.databaseManagedObjectContext invTypeWithTypeID:implant.typeID];
							if (type)
								types[@(implant.typeID)] = type;
							else
								continue;
						}

						finalAttributes.charisma += [(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCCharismaBonusAttributeID)] value];
						finalAttributes.intelligence += [(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCIntelligenceBonusAttributeID)] value];
						finalAttributes.memory += [(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCMemoryBonusAttributeID)] value];
						finalAttributes.perception += [(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCPerceptionBonusAttributeID)] value];
						finalAttributes.willpower += [(NCDBDgmTypeAttribute*) type.attributesDictionary[@(NCWillpowerBonusAttributeID)] value];
					}
				}
				NSTimeInterval optimalTrainingTime = [fullTrainingQueue trainingTimeWithCharacterAttributes:finalAttributes];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					self.optimalTrainingTime = optimalTrainingTime;
					self.optimalAttributes = optimalAttributes;
					self.fullTrainingQueue = fullTrainingQueue;
					self.skillPlan = activeSkillPlan;
					self.skillPlanName = skillPlanName;
					self.skillPlanTrainingQueue = trainingQueue;
					self.skillQueueRows = skillQueueRows;
					completionBlock();
				});
			}];


			
		});
	}
	else
		completionBlock();
}

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	self.account = [NCAccount currentAccount];
	[self reload];
}

- (id) identifierForSection:(NSInteger)section {
	return @(section);
}

#pragma mark - Unwind

- (IBAction)unwindFromSkillPlanImport:(UIStoryboardSegue*) segue {
	
}

#pragma mark - Private

- (IBAction)onSkills:(id)sender {
	[self performSegueWithIdentifier:@"NCSkillsViewController" sender:nil];
}

- (void) setAccount:(NCAccount *)account {
	_account = account;
	[account.managedObjectContext performBlock:^{
		NSString* uuid = account.uuid;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.cacheRecordID = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), uuid];
		});
	}];
}

@end
