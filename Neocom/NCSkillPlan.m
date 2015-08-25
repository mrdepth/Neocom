//
//  NCSkillPlan.m
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCSkillPlan.h"
#import "NCStorage.h"
#import "NCDatabase.h"
#import "NCAccount.h"

#define NCSkillPlanTypeIDKey @"typeID"
#define NCSkillPlanTargetLevelKey @"targetLevel"

@interface NCSkillPlan() {
	NSMutableArray* _skills;
	dispatch_group_t _loadDispatchGroup;
}

@property (nonatomic, strong) NCTrainingQueue* trainingQueue;

- (void) accountDidChange:(NSNotification*) notification;

@end

@implementation NCSkillPlan

@dynamic active;
@dynamic name;
@dynamic skills;
@dynamic account;

@synthesize trainingQueue = _trainingQueue;

- (void) awakeFromFetch {
	[super awakeFromFetch];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidChange:) name:NCAccountDidChangeNotification object:self.account];
}

- (void) awakeFromInsert {
	[super awakeFromInsert];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidChange:) name:NCAccountDidChangeNotification object:self.account];
}

- (void) didTurnIntoFault {
	[super didTurnIntoFault];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCAccountDidChangeNotification object:nil];
}

- (void) prepareForDeletion {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NCAccountDidChangeNotification object:nil];
}

- (void) setTrainingQueue:(NCTrainingQueue *)trainingQueue {
	[self willChangeValueForKey:@"trainingQueue"];
	_trainingQueue = trainingQueue;
	[self didChangeValueForKey:@"trainingQueue"];
}

- (void) save {
	if (_trainingQueue) {
		[[[NCDatabase sharedDatabase] managedObjectContext] performBlock:^{
			NSMutableArray* skills = [NSMutableArray new];
			for (NCSkillData* skill in _trainingQueue.skills) {
				NSDictionary* item = @{NCSkillPlanTypeIDKey: @(skill.type.typeID), NCSkillPlanTargetLevelKey: @(skill.targetLevel)};
				[skills addObject:item];
			}
			
			[self.managedObjectContext performBlock:^{
				self.skills = skills;
				if ([self.managedObjectContext hasChanges])
					[self.managedObjectContext save:nil];
			}];

		}];
	}
}

- (void) mergeWithTrainingQueue:(NCTrainingQueue*) trainingQueue completionBlock:(void(^)(NCTrainingQueue* trainingQueue)) completionBlock {
	[self loadTrainingQueueWithCompletionBlock:^(NCTrainingQueue *trainingQueue) {
		[[NCDatabase sharedDatabase] performBlock:^{
			NCTrainingQueue* newTrainingQueue = [trainingQueue copy];
			for (NCSkillData* skillData in trainingQueue.skills)
				[newTrainingQueue addSkill:skillData.type withLevel:skillData.targetLevel];
			self.trainingQueue = newTrainingQueue;
			if (completionBlock)
				completionBlock(trainingQueue);
			
			[self save];
		}];
	}];
}

- (void) clear {
	self.skills = nil;
	self.trainingQueue = nil;
}

- (void) loadTrainingQueueWithCompletionBlock:(void(^)(NCTrainingQueue* trainingQueue)) completionBlock {
	if (!_trainingQueue) {
		BOOL load = NO;
		dispatch_group_t loadDispatchGroup;
		@synchronized(self) {
			if (!_loadDispatchGroup) {
				_loadDispatchGroup = loadDispatchGroup = dispatch_group_create();
				dispatch_group_enter(loadDispatchGroup);
				load = YES;
			}
		}
		if (load) {
			[self.managedObjectContext performBlock:^{
				NSArray* skills = self.skills;
				[self.account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
					[[[NCDatabase sharedDatabase] managedObjectContext] performBlock:^{
						NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet];
						for (NSDictionary* item in skills) {
							int32_t typeID = [item[NCSkillPlanTypeIDKey] intValue];
							int32_t targetLevel = [item[NCSkillPlanTargetLevelKey] intValue];
							NCDBInvType* type = [NCDBInvType invTypeWithTypeID:typeID];
							if (type)
								[trainingQueue addSkill:type withLevel:targetLevel];
						}
						_trainingQueue = trainingQueue;
						dispatch_group_leave(loadDispatchGroup);
						@synchronized(self) {
							_loadDispatchGroup = nil;
						}
					}];
				}];
			}];
		}
		dispatch_group_notify(loadDispatchGroup, dispatch_get_main_queue(), ^{
			completionBlock(_trainingQueue);
		});
	}
	else
		completionBlock(_trainingQueue);
}

#pragma mark - Private

- (void) accountDidChange:(NSNotification*) notification {
	if (self.trainingQueue) {
		EVECharacterSheet* characterSheet = notification.userInfo[@"characterSheet"];
		if (characterSheet) {
			[[NCDatabase sharedDatabase] performBlock:^{
				NCTrainingQueue* trainingQueue = [self.trainingQueue copy];
				trainingQueue.characterSheet = characterSheet;
				trainingQueue.characterAttributes = [[NCCharacterAttributes alloc] initWithCharacterSheet:characterSheet];
				self.trainingQueue = trainingQueue;
			}];
		}
	}
}

@end
