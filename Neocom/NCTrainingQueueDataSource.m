//
//  NCTrainingQueueDataSource.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTrainingQueueDataSource.h"
#import "NCSkillsViewController.h"
#import "NCAccount.h"
#import "EVEOnlineAPI.h"
#import "NSString+Neocom.h"

@implementation NCTrainingQueueDataSource

- (void) reloadData {
	EVECharacterSheet* characterSheet = self.account.characterSheet;
	NSMutableArray* sections = [NSMutableArray new];
	[self.skillsViewController.taskManager addTaskWithIndentifier:NCTaskManagerIdentifierAuto
															title:NCTaskManagerDefaultTitle
															block:^(NCTask *task) {
																NSMutableArray* rows = [NSMutableArray new];
																for (EVESkillQueueItem* skill in self.skillQueue.skillQueue) {
																	NCSkillData* skillData = [[NCSkillData alloc] initWithTypeID:skill.typeID error:nil];
																	if (skillData) {
																		EVECharacterSheetSkill* characterSkill = characterSheet.skillsMap[@(skill.typeID)];
																		skillData.targetLevel = skill.level;
																		skillData.currentLevel = skill.level - 1;
																		skillData.skillPoints = characterSkill.skillpoints;
																		[rows addObject:skillData];
																	}
																}
																
																NSString* title;

																if (self.skillQueue.skillQueue.count > 0) {
																	NSDate *endTime = [[self.skillQueue.skillQueue lastObject] endTime];
																	NSTimeInterval timeLeft = [endTime timeIntervalSinceDate:[self.skillQueue serverTimeWithLocalTime:[NSDate date]]];
																	title = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NSString stringWithTimeLeft:timeLeft], self.skillQueue.skillQueue.count];
																}
																else {
																	title = NSLocalizedString(@"Training queue is inactive", nil);
																}
																[sections addObject:@{@"title": title, @"rows": rows}];
																if (self.skillPlan.trainingQueue.skills.count > 0)
																	title = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills)", nil), [NSString stringWithTimeLeft:self.skillPlan.trainingQueue.trainingTime], self.skillPlan.trainingQueue.skills.count];
																else
																	title = NSLocalizedString(@"Skill plan in empty", nil);
																[sections addObject:@{@"title": title, @"rows": [self.skillPlan.trainingQueue.skills copy]}];
															}
												completionHandler:^(NCTask *task) {
													if (self.skillsViewController.tableView.dataSource == self)
														[self.skillsViewController.tableView reloadData];
												}];
}

@end
