//
//  NCSkillsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillsViewController.h"
#import <EVEAPI/EVEAPI.h>
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

@interface NCSkillsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) EVESkillQueue* skillQueue;
@property (nonatomic, strong) EVECharacterSheet* characterSheet;
@property (nonatomic, strong) NCCharacterAttributes* characterAttributes;
@end


@interface NCSkillsViewControllerSection : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* groupName;
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, assign) int32_t groupID;
@end

@interface NCSkillsViewController ()
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) NSArray* allSkillsSections;
@property (nonatomic, strong) NSArray* knownSkillsSections;
@property (nonatomic, strong) NSArray* notKnownSkillsSections;
@property (nonatomic, strong) NSArray* canTrainSkillsSections;
@property (nonatomic, strong) NSMutableDictionary* types;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;

@end

@implementation NCSkillsViewControllerData

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

@implementation NCSkillsViewControllerSection;

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
//	self.refreshControl = nil;
	self.types = [NSMutableDictionary new];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	self.account = [NCAccount currentAccount];
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
		controller.typeID = [[self.databaseManagedObjectContext invTypeWithTypeID:[sender skillData].typeID] objectID];
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

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (NSString*)tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
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
	
	if (row.trainedLevel >= 0)
		return @"NCSkillCell";
	else
		return @"NCSkillCompactCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCSkillData* row;
	NCSkillsViewControllerData* data = self.cacheData;

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

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
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
				NCSkillsViewControllerData* data = [NCSkillsViewControllerData new];
				
				dispatch_group_t finishDispatchGroup = dispatch_group_create();
				
				dispatch_group_enter(finishDispatchGroup);
				[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
					if (error)
						lastError = error;
					data.characterAttributes = [[NCCharacterAttributes alloc] initWithCharacterSheet:characterSheet];
					data.characterSheet = characterSheet;
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
	void (^load)() = ^{
		NCSkillsViewControllerData* data = cacheData;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			NSMutableDictionary* allSkillsMap = [NSMutableDictionary new];
			
			NSMutableArray* knownSkillsSections = [NSMutableArray new];
			NSMutableArray* canTrainSkillsSections = [NSMutableArray new];
			NSMutableArray* notKnownSkillsSections = [NSMutableArray new];
			
			for (NCSkillsViewControllerSection* section in self.allSkillsSections) {
				NSMutableArray* knownSkills = [NSMutableArray new];
				NSMutableArray* canTrainSkills = [NSMutableArray new];
				NSMutableArray* notKnownSkills = [NSMutableArray new];
				
				int32_t skillPoints = 0;
				
				for (NCSkillData* skill in section.rows) {
					skill.characterSkill = data.characterSheet.skillsMap[@(skill.typeID)];
					skill.characterAttributes = data.characterAttributes;

					if (skill.characterSkill) {
						if (skill.trainedLevel < 5)
							[canTrainSkills addObject:skill];
						[knownSkills addObject:skill];
						skillPoints += skill.skillPoints;
					}
					else {
						[notKnownSkills addObject:skill];
						[canTrainSkills addObject:skill];
					}
					allSkillsMap[@(skill.typeID)] = skill;
				}
				
				NSString* title = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ skillpoints)", nil),
								   section.groupName,
								   [NSNumberFormatter neocomLocalizedStringFromNumber:@(skillPoints)]];
				int32_t groupID = section.groupID;
				
				section.title = title;
				
				if (knownSkills.count > 0) {
					NCSkillsViewControllerSection* section = [NCSkillsViewControllerSection new];
					section.title = title;
					section.rows = knownSkills;
					section.groupID = groupID;
					[knownSkillsSections addObject:section];
				}
				if (canTrainSkills.count > 0) {
					NCSkillsViewControllerSection* section = [NCSkillsViewControllerSection new];
					section.title = title;
					section.rows = canTrainSkills;
					section.groupID = groupID;
					[canTrainSkillsSections addObject:section];
				}
				if (notKnownSkills.count > 0) {
					NCSkillsViewControllerSection* section = [NCSkillsViewControllerSection new];
					section.title = title;
					section.rows = notKnownSkills;
					section.groupID = groupID;
					[notKnownSkillsSections addObject:section];
				}
			}
			
			for (EVESkillQueueItem *item in data.skillQueue.skillQueue) {
				NCSkillData* skillData = allSkillsMap[@(item.typeID)];
				skillData.targetLevel = item.level;
				skillData.currentLevel = item.level - 1;
			}

			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.knownSkillsSections = knownSkillsSections;
				self.canTrainSkillsSections = canTrainSkillsSections;
				self.notKnownSkillsSections = notKnownSkillsSections;
				completionBlock();
			});
		});
	};
	
	if (!self.allSkillsSections) {
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		[databaseManagedObjectContext performBlock:^{
			NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
			request.predicate = [NSPredicate predicateWithFormat:@"published == TRUE AND group.category.categoryID == 16"];
			request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"group.groupName" ascending:YES],
										[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
			NSFetchedResultsController* result = [[NSFetchedResultsController alloc] initWithFetchRequest:request
																					 managedObjectContext:databaseManagedObjectContext
																					   sectionNameKeyPath:@"group.groupName"
																								cacheName:nil];
			[result performFetch:nil];
			NSMutableArray* allSkillsSections = [NSMutableArray new];

			for (id<NSFetchedResultsSectionInfo> sectionInfo in result.sections) {
				NSMutableArray* allSkills = [NSMutableArray new];
				
				NCDBInvGroup* group = nil;
				
				for (NCDBInvType* type in sectionInfo.objects) {
					if (!group)
						group = type.group;
					NCSkillData* skillData = [[NCSkillData alloc] initWithInvType:type];
					[allSkills addObject:skillData];
				}
				
				if (allSkills.count > 0) {
					NCSkillsViewControllerSection* section = [NCSkillsViewControllerSection new];
					section.rows = allSkills;
					section.groupName = sectionInfo.name;
					section.groupID = group.groupID;
					[allSkillsSections addObject:section];
				}
			}
			dispatch_async(dispatch_get_main_queue(), ^{
				self.allSkillsSections = allSkillsSections;
				load();
			});
		}];
	}
	else {
		load();
	}
}

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	self.account = [NCAccount currentAccount];
	[self reload];
}

- (id) identifierForSection:(NSInteger)section {
	switch (self.mode) {
		case NCSkillsViewControllerModeKnownSkills:
			return @([self.knownSkillsSections[section] groupID]);
		case NCSkillsViewControllerModeAllSkills:
			return @([self.allSkillsSections[section] groupID]);
		case NCSkillsViewControllerModeNotKnownSkills:
			return @([self.notKnownSkillsSections[section] groupID]);
		case NCSkillsViewControllerModeCanTrainSkills:
			return @([self.canTrainSkillsSections[section] groupID]);
		default:
			return nil;
	}
}

- (BOOL) initiallySectionIsCollapsed:(NSInteger)section {
	return YES;
}

#pragma mark - Private

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
