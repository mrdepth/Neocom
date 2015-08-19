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
	NSMutableArray* _completionBlocks;
}

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
	NSMutableArray* skills = [NSMutableArray new];
	[[NCDatabase sharedDatabase] performBlockAndWait:^{
		for (NCSkillData* skill in self.trainingQueue.skills) {
			NSDictionary* item = @{NCSkillPlanTypeIDKey: @(skill.type.typeID), NCSkillPlanTargetLevelKey: @(skill.targetLevel)};
			[skills addObject:item];
		}
	}];
	
	self.skills = skills;

	[self.managedObjectContext performBlock:^{
		if ([self.managedObjectContext hasChanges])
			[self.managedObjectContext save:nil];
	}];
}

- (void) mergeWithTrainingQueue:(NCTrainingQueue*) trainingQueue {
	[[NCDatabase sharedDatabase] performBlockAndWait:^{
		NCTrainingQueue* newTrainingQueue = [self.trainingQueue copy];
		for (NCSkillData* skillData in trainingQueue.skills)
			[newTrainingQueue addSkill:skillData.type withLevel:skillData.targetLevel];
		self.trainingQueue = newTrainingQueue;
	}];
	[self save];
}

- (void) removeSkill:(NCSkillData *)skill {
	NCTrainingQueue* newTrainingQueue = [self.trainingQueue copy];
	[newTrainingQueue removeSkill:skill];
	self.trainingQueue = newTrainingQueue;
	[self save];
}

- (void) clear {
	self.skills = nil;
	self.trainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:self.trainingQueue.characterSheet];
}

- (BOOL) isLoaded {
	return _trainingQueue != nil;
}

- (void) loadWithCompletionBlock:(void(^)()) completionBlock {
	if (![self isLoaded]) {
		BOOL load;
		@synchronized(self) {
			load = !_completionBlocks || _completionBlocks.count == 0;
			if (!_completionBlocks)
				_completionBlocks = [NSMutableArray new];
			[_completionBlocks addObject:completionBlock];
		}
		if (!load)
			return;

		[self.account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
			[[[NCDatabase sharedDatabase] managedObjectContext] performBlock:^{
				NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet];
				for (NSDictionary* item in self.skills) {
					int32_t typeID = [item[NCSkillPlanTypeIDKey] intValue];
					int32_t targetLevel = [item[NCSkillPlanTargetLevelKey] intValue];
					NCDBInvType* type = [NCDBInvType invTypeWithTypeID:typeID];
					if (type)
						[trainingQueue addSkill:type withLevel:targetLevel];
				}
				_trainingQueue = trainingQueue;
				dispatch_async(dispatch_get_main_queue(), ^{
					@synchronized(self) {
						for (void(^block)() in _completionBlocks)
							block();
						_completionBlocks = nil;
					}
				});
			}];
		}];
	}
	else
		completionBlock();
}

#pragma mark - Private

- (void) accountDidChange:(NSNotification*) notification {
	if (self.trainingQueue) {
		EVECharacterSheet* characterSheet = notification.userInfo[@"characterSheet"];
		if (characterSheet) {
			self.trainingQueue.characterSheet = characterSheet;
			self.trainingQueue.characterAttributes = [[NCCharacterAttributes alloc] initWithCharacterSheet:characterSheet];
		}
	}
}

@end
