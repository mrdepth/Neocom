//
//  TrainingQueue.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TrainingQueue.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "EVEOnlineAPI.h"
#import "EVEDBAPI.h"
#import "EVEDBCrtCertificate+TrainingQueue.h"
#import "EVEDBInvType+TrainingQueue.h"
#import <objc/runtime.h>

@implementation EVEDBInvTypeRequiredSkill(TrainingQueueSkill)

- (NSInteger) currentLevel {
	NSNumber* currentLevel = objc_getAssociatedObject(self, @"currentLevel");
	return [currentLevel integerValue];
}

- (void) setCurrentLevel:(NSInteger) value {
	objc_setAssociatedObject(self, @"currentLevel", [NSNumber numberWithInteger:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self setCurrentSP:[self skillpointsAtLevel:value]];
}

- (float) currentSP {
	NSNumber* currentSP = objc_getAssociatedObject(self, @"currentSP");
	return [currentSP floatValue];
}

- (void) setCurrentSP:(float) value {
	objc_setAssociatedObject(self, @"currentSP", [NSNumber numberWithInteger:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface TrainingQueue()
@property (nonatomic, strong) EVEAccount *account;
@property (nonatomic, strong) NSDictionary *characterSkills;
@property (nonatomic, readwrite, assign) NSTimeInterval trainingTime;

@end


@implementation TrainingQueue

+ (id) trainingQueueWithType: (EVEDBInvType*) type {
	return [[TrainingQueue alloc] initWithType:type];
}

+ (id) trainingQueueWithCertificate: (EVEDBCrtCertificate*) certificate {
	return [[TrainingQueue alloc] initWithCertificate:certificate];
}

+ (id) trainingQueueWithRequiredSkills: (NSArray*) requiredSkills {
	return [[TrainingQueue alloc] initWithRequiredSkills:requiredSkills];
}

- (id) init {
	if (self = [super init]) {
		self.account = [EVEAccount currentAccount];
		self.characterSkills = [NSMutableDictionary dictionary];
		self.trainingTime = -1;
		if (self.account && self.account.characterSheet) {
			for (EVECharacterSheetSkill *skill in self.account.characterSheet.skills) {
				[self.characterSkills setValue:skill forKey:[NSString stringWithFormat:@"%d", skill.typeID]];
			}
		}
		else {
			self.account = [EVEAccount dummyAccount];
		}
		
		self.skills = [NSMutableArray array];
	}
	return self;
}

- (id) initWithType: (EVEDBInvType*) type {
	if (self = [self initWithRequiredSkills:type.requiredSkills]) {
	}
	return self;
}

- (id) initWithCertificate: (EVEDBCrtCertificate*) certificate {
	if (self = [self init]) {
		for (EVEDBCrtRelationship* relationship in certificate.prerequisites) {
			if (relationship.parentType) {
				[self addSkill:relationship.parentType];
			}
			else if (relationship.parent) {
				for (EVEDBInvTypeRequiredSkill* item in relationship.parent.trainingQueue.skills)
					[self addSkill:item];
			}
		}
		self.trainingTime = -1;
	}
	return self;
}

- (id) initWithRequiredSkills: (NSArray*) requiredSkills {
	if (self = [self init]) {
		for (EVEDBInvTypeRequiredSkill* skill in requiredSkills) {
			[self addSkill:skill];
		}
	}
	return self;
}

- (NSTimeInterval) trainingTime {
	if (_trainingTime < 0) {
		_trainingTime = 0;
		
		for (EVEDBInvTypeRequiredSkill *skill in self.skills) {
			if (skill.currentLevel < skill.requiredLevel)
				_trainingTime += (skill.requiredSP - skill.currentSP) / [self.account.characterAttributes skillpointsPerSecondForSkill:skill];
		}
	}
	return _trainingTime;
}

- (void) addSkill:(EVEDBInvTypeRequiredSkill*) skill {
	int i = 0;
	EVECharacterSheetSkill *characterSkill = [self.characterSkills valueForKey:[NSString stringWithFormat:@"%d", skill.typeID]];
	skill.currentLevel = characterSkill.level;
	skill.currentSP = characterSkill.skillpoints;
	if (skill.currentLevel >= skill.requiredLevel)
		return;
	
	for (EVEDBInvTypeRequiredSkill *item in self.skills) {
		if (item.typeID == skill.typeID) {
			if (skill.requiredLevel > item.requiredLevel)
				[self.skills replaceObjectAtIndex:i withObject:skill];
			return;
		}
		i++;
	}
	
	[self.skills insertObject:skill atIndex:0];
	self.trainingTime = -1;
	for (EVEDBInvTypeRequiredSkill* requiredSkill in skill.requiredSkills)
		[self addSkill:requiredSkill];
}

@end
