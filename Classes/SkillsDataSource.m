//
//  SkillsDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 23.07.13.
//
//

#import "SkillsDataSource.h"
#import "EUOperationQueue.h"
#import "EVEAccount.h"
#import "NSString+TimeLeft.h"
#import "EVEDBAPI.h"
#import "NSArray+GroupBy.h"
#import "NSNumberFormatter+Neocom.h"
#import "SkillCellView.h"
#import "UITableViewCell+Nib.h"
#import "UIImageView+GIF.h"

@interface SkillGroup : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* skills;
@end

@implementation SkillGroup
@end

@interface SkillData : EVEDBInvType
@property (nonatomic, copy) NSString* title;
@property (nonatomic, assign) NSInteger trainedLevel;
@property (nonatomic, assign) NSInteger targetLevel;
@property (nonatomic, assign) float skillPoints;
@property (nonatomic, assign) float progress;
@property (nonatomic, assign, getter = isActive) BOOL active;
@property (nonatomic, assign) NSTimeInterval remainingTime;
@end

@implementation SkillData
@end

@interface SkillsDataSource()
@property (nonatomic, strong) NSArray* skillQueue;
@property (nonatomic, strong) NSArray* allSkills;
@property (nonatomic, strong) NSArray* knownSkills;
@property (nonatomic, strong) NSArray* notKnownSkills;
@property (nonatomic, strong) NSArray* canTrainSkills;
@property (nonatomic, strong) NSMutableArray* skillPlan;
@property (nonatomic, strong) NSString* skillQueueTitle;
@property (nonatomic, strong) NSDate* currentTime;

- (void) reloadSkillQueue;
- (void) didAddSkill:(NSNotification*) notification;
- (void) didChangeSkill:(NSNotification*) notification;
- (void) didRemoveSkill:(NSNotification*) notification;

@end

@implementation SkillsDataSource

- (void) awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddSkill:) name:NotificationSkillPlanDidAddSkill object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeSkill:) name:NotificationSkillPlanDidChangeSkill object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemoveSkill:) name:NotificationSkillPlanDidRemoveSkill object:nil];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) reload {
	[self.account updateSkillpoints];
	self.currentTime = [self.account.skillQueue serverTimeWithLocalTime:[NSDate date]];

	if (self.mode == SkillsDataSourceModeSkillPlanner) {
		[self reloadSkillQueue];
		[self reloadSkillPlan];
	}
	else {
		[self reloadSkills];
	}
}

- (EVEDBInvType*) skillAtIndexPath:(NSIndexPath*) indexPath {
	SkillData* skill;
	
	switch (self.mode) {
		case SkillsDataSourceModeSkillPlanner:
			skill = indexPath.section == 0 ? self.skillQueue[indexPath.row] : self.skillPlan[indexPath.row];
			break;
		case SkillsDataSourceModeKnownSkills:
			skill = [self.knownSkills[indexPath.section] skills][indexPath.row];
			break;
		case SkillsDataSourceModeNotKnownSkills:
			skill = [self.notKnownSkills[indexPath.section] skills][indexPath.row];
			break;
		case SkillsDataSourceModeCanTrain:
			skill = [self.canTrainSkills[indexPath.section] skills][indexPath.row];
			break;
		case SkillsDataSourceModeAllSkills:
			skill = [self.allSkills[indexPath.section] skills][indexPath.row];
			break;
		default:
			skill = nil;
			break;
	}
	return skill;
}

- (void) setMode:(SkillsDataSourceMode)mode {
	_mode = mode;
	if (self.mode == SkillsDataSourceModeSkillPlanner) {
		if (!self.skillPlan)
			[self reloadSkillPlan];
		if (!self.skillQueue)
			[self reloadSkillQueue];
	}
	else {
		if (!self.allSkills)
			[self reloadSkills];
	}
	[self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	switch (self.mode) {
		case SkillsDataSourceModeSkillPlanner:
			return self.skillQueue ? (self.skillPlan ? 2 : 1) : 0;
		case SkillsDataSourceModeKnownSkills:
			return self.knownSkills.count;
		case SkillsDataSourceModeNotKnownSkills:
			return self.notKnownSkills.count;
		case SkillsDataSourceModeCanTrain:
			return self.canTrainSkills.count;
		case SkillsDataSourceModeAllSkills:
			return self.allSkills.count;
		default:
			return 0;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (self.mode) {
		case SkillsDataSourceModeSkillPlanner:
			return section == 0 ? self.skillQueue.count : self.skillPlan.count;
		case SkillsDataSourceModeKnownSkills:
			return [[self.knownSkills[section] skills] count];
		case SkillsDataSourceModeNotKnownSkills:
			return [[self.notKnownSkills[section] skills] count];
		case SkillsDataSourceModeCanTrain:
			return [[self.canTrainSkills[section] skills] count];
		case SkillsDataSourceModeAllSkills:
			return [[self.allSkills[section] skills] count];
		default:
			return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString* cellIdentifier = @"SkillCellView";
	SkillCellView* cell = (SkillCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell)
		cell = [SkillCellView cellWithNibName:@"SkillCellView" bundle:nil reuseIdentifier:cellIdentifier];
	
	SkillData* skill = (SkillData*) [self skillAtIndexPath:indexPath];
	
	cell.iconImageView.image = [UIImage imageNamed:skill.active ? @"Icons/icon50_12.png" : (skill.trainedLevel == 5 ? @"Icons/icon50_14.png" : @"Icons/icon50_13.png")];

	cell.skillLabel.text = skill.title;
	if (skill.trainedLevel >= 0) {
		float progress = 0;

		if (skill.targetLevel == skill.trainedLevel + 1) {
			float startSkillPoints = [skill skillPointsAtLevel:skill.trainedLevel];
			float targetSkillPoints = [skill skillPointsAtLevel:skill.targetLevel];
			
			progress = (skill.skillPoints - startSkillPoints) / (targetSkillPoints - startSkillPoints);
			if (progress > 1.0)
				progress = 1.0;
		}
		
		cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SP: %@ (%@ SP/h)", nil),
									  [NSNumberFormatter neocomLocalizedStringFromNumber:@(skill.skillPoints)],
									  [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.account.characterAttributes skillpointsPerSecondForSkill:skill] * 3600)]];
		cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), MAX(skill.targetLevel,skill.trainedLevel)];
		[cell.levelImageView setGIFImageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"level_%d%d%d", skill.trainedLevel, skill.targetLevel, skill.active] withExtension:@"gif"]];
		cell.remainingLabel.text = skill.remainingTime > 0 ? [NSString stringWithFormat:@"%@ (%.0f%%)", [NSString stringWithTimeLeft:skill.remainingTime], progress * 100] : nil;
	}
	else {
		cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ SP/h", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@([self.account.characterAttributes skillpointsPerSecondForSkill:skill] * 3600)]];
		cell.levelLabel.text = nil;
		cell.levelImageView.image = nil;
		cell.remainingLabel.text = nil;
	}
	

	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	
	return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (self.mode == SkillsDataSourceModeSkillPlanner) {
		if (section == 0)
			return self.skillQueueTitle;
		else
			return self.account.skillPlan.skills.count > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Skill plan (%@)", nil), [NSString stringWithTimeLeft:self.account.skillPlan.trainingTime]] :
			NSLocalizedString(@"Skill plan is empty", nil);
	}
	else if (self.mode == SkillsDataSourceModeKnownSkills)
		return [self.knownSkills[section] title];
	else if (self.mode == SkillsDataSourceModeNotKnownSkills)
		return [self.notKnownSkills[section] title];
	else if (self.mode == SkillsDataSourceModeAllSkills)
		return [self.allSkills[section] title];
	else if (self.mode == SkillsDataSourceModeCanTrain)
		return [self.canTrainSkills[section] title];
	else
		return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.mode == SkillsDataSourceModeSkillPlanner && indexPath.section == 1;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.mode == SkillsDataSourceModeSkillPlanner && indexPath.section == 1;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	NSObject *objectToMove = [self.account.skillPlan.skills objectAtIndex:fromIndexPath.row];
    [self.account.skillPlan.skills removeObjectAtIndex:fromIndexPath.row];
    [self.account.skillPlan.skills insertObject:objectToMove atIndex:toIndexPath.row];
	[self.account.skillPlan save];

	objectToMove = [self.skillPlan objectAtIndex:fromIndexPath.row];
    [self.skillPlan removeObjectAtIndex:fromIndexPath.row];
    [self.skillPlan insertObject:objectToMove atIndex:toIndexPath.row];

	double delayInSeconds = 0.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		for (GroupedCell* cell in tableView.visibleCells) {
			NSIndexPath* indexPath = [tableView indexPathForCell:cell];
			GroupedCellGroupStyle groupStyle = 0;
			if (indexPath.row == 0)
				groupStyle |= GroupedCellGroupStyleTop;
			if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
				groupStyle |= GroupedCellGroupStyleBottom;
			cell.groupStyle = groupStyle;
		}
	});
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSArray* oldSkills = [self.account.skillPlan.skills copy];

		[self.account.skillPlan removeSkill:[self.account.skillPlan.skills objectAtIndex:indexPath.row]];
		[self.account.skillPlan save];

		NSMutableIndexSet* indexSet = [[NSMutableIndexSet alloc] init];
		NSMutableArray* indexes = [[NSMutableArray alloc] init];
		int i = 0;
		for (EVEDBInvTypeRequiredSkill* skill in oldSkills) {
			if (![self.account.skillPlan.skills containsObject:skill]) {
				[indexSet addIndex:i];
				[indexes addObject:[NSIndexPath indexPathForRow:i inSection:1]];
			}
			i++;
		}
		
		[self.skillPlan removeObjectsAtIndexes:indexSet];
		//[tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
		[tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - Private

- (void) reloadSkillQueue {
	EVEAccount* account = self.account;
	if (!account) {
		self.skillQueue = nil;
		self.skillPlan = nil;
		self.skillQueueTitle = nil;
		[self.tableView reloadData];
		return;
	}

	EUOperation* operation = [EUOperation operationWithIdentifier:@"SkillsDataSource+reloadSkillQueue" name:NSLocalizedString(@"Loading...", nil)];
	__weak EUOperation* weakOperation = operation;
	
	NSMutableArray* skillQueue = [NSMutableArray array];
	__block NSString* skillQueueTitle = nil;
	
	[operation addExecutionBlock:^{
		[account updateSkillpoints];
		
		for (EVESkillQueueItem *item in account.skillQueue.skillQueue) {
			SkillData* skillData = [[SkillData alloc] initWithTypeID:item.typeID error:nil];
			if (!skillData)
				continue;
			
			EVECharacterSheetSkill* learnedSkill = account.characterSheet.skillsMap[@(item.typeID)];
			skillData.trainedLevel = learnedSkill.level;
			skillData.skillPoints = learnedSkill.skillpoints;
			
			skillData.targetLevel = item.level;
			skillData.active = item.queuePosition == 0;
			
			float sps = [account.characterAttributes skillpointsPerSecondForSkill:skillData];
			if (skillData.targetLevel == skillData.trainedLevel + 1)
				skillData.remainingTime = ([skillData skillPointsAtLevel:skillData.targetLevel] - skillData.skillPoints) / sps;
			else
				skillData.remainingTime = ([skillData skillPointsAtLevel:skillData.targetLevel] - [skillData skillPointsAtLevel:skillData.targetLevel - 1]) / sps;
			
			EVEDBDgmTypeAttribute *attribute = skillData.attributesDictionary[@(275)];
			skillData.title = [NSString stringWithFormat:@"%@ (x%d)", skillData.typeName, (int) attribute.value];
			
			[skillQueue addObject:skillData];
		}
		
		if (account.skillQueue.skillQueue.count == 0)
			skillQueueTitle = [[NSString alloc] initWithFormat:NSLocalizedString(@"Training queue is inactive.", nil)];
		else {
			EVESkillQueueItem *lastSkill = [account.skillQueue.skillQueue lastObject];
			if (lastSkill.endTime) {
				NSTimeInterval remainingTime = [lastSkill.endTime timeIntervalSinceDate:self.currentTime];
				skillQueueTitle = [[NSString alloc] initWithFormat:NSLocalizedString(@"Skill Queue (%@)", nil),
								   [NSString stringWithTimeLeft:remainingTime]];
			}
			else
				skillQueueTitle = [[NSString alloc] initWithString:NSLocalizedString(@"Training queue is inactive", nil)];
		}
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			self.skillQueue = skillQueue;
			self.skillQueueTitle = skillQueueTitle;
			
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) reloadSkills {
	EVEAccount* account = self.account;
	if (!account) {
		self.knownSkills = nil;
		self.allSkills = nil;
		self.canTrainSkills = nil;
		self.notKnownSkills = nil;
		[self.tableView reloadData];
		return;
	}

	EUOperation* operation = [EUOperation operationWithIdentifier:@"SkillsDataSource+reloadSkills" name:NSLocalizedString(@"Loading...", nil)];
	__weak EUOperation* weakOperation = operation;
	
	NSMutableArray* knownSkillsGroups = [NSMutableArray array];
	NSMutableArray* allGroups = [NSMutableArray array];
	NSMutableArray* canTrainGroups = [NSMutableArray array];
	NSMutableArray* notKnownGroups = [NSMutableArray array];
	
	[operation addExecutionBlock:^{
		NSMutableDictionary* skills = [[NSMutableDictionary alloc] init];
		
		[[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT a.* FROM invTypes as a, invGroups as b where a.groupID=b.groupID and b.categoryID=16 and a.published = 1"
										   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
											   if ([weakOperation isCancelled])
												   *needsMore = NO;
											   
											   SkillData* skillData = [[SkillData alloc] initWithStatement:stmt];
											   EVEDBDgmTypeAttribute *attribute = skillData.attributesDictionary[@(275)];
											   skillData.title = [NSString stringWithFormat:@"%@ (x%d)", skillData.typeName, (int) attribute.value];
											   skillData.trainedLevel = -1;
											   
											   skills[@(skillData.typeID)] = skillData;
										   }];
		
		NSMutableArray* knownSkills = [NSMutableArray array];
		
		for (EVECharacterSheetSkill* characterSheetSkill in account.characterSheet.skills) {
			SkillData* skillData = skills[@(characterSheetSkill.typeID)];
			if (skillData) {
				skillData.trainedLevel = characterSheetSkill.level;
				skillData.skillPoints = characterSheetSkill.skillpoints;
				[knownSkills addObject:skillData];
			}
		}
		[knownSkills sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
		
		for (EVESkillQueueItem *item in account.skillQueue.skillQueue) {
			SkillData* skillData = skills[@(item.typeID)];

			NSTimeInterval remainingTime = 0;
			float sps = [account.characterAttributes skillpointsPerSecondForSkill:skillData];
			if (skillData.targetLevel == skillData.trainedLevel + 1)
				remainingTime = ([skillData skillPointsAtLevel:skillData.targetLevel] - skillData.skillPoints) / sps;
			else
				remainingTime = ([skillData skillPointsAtLevel:skillData.targetLevel] - [skillData skillPointsAtLevel:skillData.targetLevel - 1]) / sps;
			
			skillData.targetLevel = item.level;
			if (item.queuePosition == 0)
				skillData.active = YES;
			if (remainingTime > 0 && item.level == skillData.trainedLevel + 1)
				skillData.remainingTime = remainingTime;
		}
		
		for (NSArray* array in [knownSkills arrayGroupedByKey:@"groupID"]) {
			SkillGroup* group = [[SkillGroup alloc] init];
			group.skills = array;
			float skillPoints = 0;
			for (SkillData* skill in array) {
				skillPoints += skill.skillPoints;
			}
			group.title = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ skillpoints)", nil),
						   [[array[0] group] groupName],
						   [NSNumberFormatter neocomLocalizedStringFromNumber:@(skillPoints)]];
			[knownSkillsGroups addObject:group];
		}
		[knownSkillsGroups sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
		
		for (NSArray* array in [[[skills allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]] arrayGroupedByKey:@"groupID"]) {
			SkillGroup* group = [[SkillGroup alloc] init];
			group.skills = array;
			float skillPoints = 0;
			for (SkillData* skill in array) {
				skillPoints += skill.skillPoints;
			}
			group.title = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ skillpoints)", nil),
						   [[array[0] group] groupName],
						   [NSNumberFormatter neocomLocalizedStringFromNumber:@(skillPoints)]];
			[allGroups addObject:group];
		}
		[allGroups sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
		
		NSPredicate* predicate = nil;
		
		predicate = [NSPredicate predicateWithFormat:@"trainedLevel < 5 AND trainedLevel >= 0"];
		for (SkillGroup* group in allGroups) {
			NSArray* canTrain = [group.skills filteredArrayUsingPredicate:predicate];
			if (canTrain.count > 0) {
				SkillGroup* canTrainGroup = [[SkillGroup alloc] init];
				canTrainGroup.skills = canTrain;
				canTrainGroup.title = group.title;
				[canTrainGroups addObject:canTrainGroup];
			}
		}

		predicate = [NSPredicate predicateWithFormat:@"trainedLevel < 0"];
		for (SkillGroup* group in allGroups) {
			NSArray* notKnown = [group.skills filteredArrayUsingPredicate:predicate];
			if (notKnown.count > 0) {
				SkillGroup* notKnownGroup = [[SkillGroup alloc] init];
				notKnownGroup.skills = notKnown;
				notKnownGroup.title = group.title;
				[notKnownGroups addObject:notKnownGroup];
			}
		}
		
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			self.knownSkills = knownSkillsGroups;
			self.notKnownSkills = notKnownGroups;
			self.allSkills = allGroups;
			self.canTrainSkills = canTrainGroups;
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) reloadSkillPlan {
	EUOperation* operation = [EUOperation operationWithIdentifier:@"SkillsDataSource+reloadSkillPlan" name:NSLocalizedString(@"Loading...", nil)];
	__weak EUOperation* weakOperation = operation;
	
	NSMutableArray* skillPlan = [NSMutableArray array];
	EVEAccount* account = self.account;
	
	[operation addExecutionBlock:^{
		
		[account.skillPlan resetTrainingTime];
		[account.skillPlan trainingTime];
		
		for (EVEDBInvTypeRequiredSkill* skillPlanSkill in account.skillPlan.skills) {
			SkillData* skillData = [[SkillData alloc] initWithTypeID:skillPlanSkill.typeID error:nil];
			if (skillData) {
				EVEDBDgmTypeAttribute *attribute = skillData.attributesDictionary[@(275)];
				skillData.title = [NSString stringWithFormat:@"%@ (x%d)", skillData.typeName, (int) attribute.value];
				EVECharacterSheetSkill* trainedSkill = account.characterSheet.skillsMap[@(skillData.typeID)];
				skillData.trainedLevel = trainedSkill.level;
				skillData.targetLevel = skillPlanSkill.requiredLevel;
				skillData.skillPoints = trainedSkill.skillpoints;
				
				float sps = [account.characterAttributes skillpointsPerSecondForSkill:skillData];
				if (skillData.targetLevel == skillData.trainedLevel + 1)
					skillData.remainingTime = ([skillData skillPointsAtLevel:skillData.targetLevel] - skillData.skillPoints) / sps;
				else
					skillData.remainingTime = ([skillData skillPointsAtLevel:skillData.targetLevel] - [skillData skillPointsAtLevel:skillData.targetLevel - 1]) / sps;
				
				EVESkillQueueItem* queuedSkill;
				for (queuedSkill in account.skillQueue.skillQueue)
					if (queuedSkill.typeID == skillData.typeID && queuedSkill.level == skillData.targetLevel)
						break;
				
				if (queuedSkill) {
					skillData.active = queuedSkill.queuePosition == 0;
					
					if (queuedSkill.endTime)
						skillData.remainingTime = [queuedSkill.endTime timeIntervalSinceDate:queuedSkill.queuePosition == 0 ? self.currentTime : queuedSkill.startTime];
				}
				[skillPlan addObject:skillData];
			}
		}
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			self.skillPlan = skillPlan;
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) didAddSkill:(NSNotification*) notification {
	if (notification.object == self.account.skillPlan) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadSkillPlan) object:nil];
		[self performSelector:@selector(reloadSkillPlan) withObject:nil afterDelay:0];
	}
}

- (void) didChangeSkill:(NSNotification*) notification {
}

- (void) didRemoveSkill:(NSNotification*) notification {
}

@end
