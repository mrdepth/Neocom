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


@implementation TrainingQueue
@synthesize skills;
@synthesize trainingTime;

+ (id) trainingQueueWithType: (EVEDBInvType*) type {
	return [[[TrainingQueue alloc] initWithType:type] autorelease];
}

+ (id) trainingQueueWithCertificate: (EVEDBCrtCertificate*) certificate {
	return [[[TrainingQueue alloc] initWithCertificate:certificate] autorelease];
}

+ (id) trainingQueueWithRequiredSkills: (NSArray*) requiredSkills {
	return [[[TrainingQueue alloc] initWithRequiredSkills:requiredSkills] autorelease];
}

- (id) init {
	if (self = [super init]) {
		account = [[EVEAccount currentAccount] retain];
		characterSkills = [[NSMutableDictionary dictionary] retain];
		trainingTime = -1;
		if (account && account.characterSheet) {
			for (EVECharacterSheetSkill *skill in account.characterSheet.skills) {
				[characterSkills setValue:skill forKey:[NSString stringWithFormat:@"%d", skill.typeID]];
			}
		}
		else {
			account = [[EVEAccount dummyAccount] retain];
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
		trainingTime = -1;
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

- (void) dealloc {
	[skills release];
	[account release];
	[characterSkills release];
	[super dealloc];
}

- (NSTimeInterval) trainingTime {
	if (trainingTime < 0) {
		trainingTime = 0;
		
		for (EVEDBInvTypeRequiredSkill *skill in skills) {
			if (skill.currentLevel < skill.requiredLevel)
				trainingTime += (skill.requiredSP - skill.currentSP) / [account.characterAttributes skillpointsPerSecondForSkill:skill];
		}
	}
	return trainingTime;
}

- (void) addSkill:(EVEDBInvTypeRequiredSkill*) skill {
	int i = 0;
	EVECharacterSheetSkill *characterSkill = [characterSkills valueForKey:[NSString stringWithFormat:@"%d", skill.typeID]];
	skill.currentLevel = characterSkill.level;
	skill.currentSP = characterSkill.skillpoints;
	if (skill.currentLevel >= skill.requiredLevel)
		return;
	
	for (EVEDBInvTypeRequiredSkill *item in skills) {
		if (item.typeID == skill.typeID) {
			if (skill.requiredLevel > item.requiredLevel)
				[skills replaceObjectAtIndex:i withObject:skill];
			return;
		}
		i++;
	}
	
	[skills insertObject:skill atIndex:0];
	trainingTime = -1;
	for (EVEDBInvTypeRequiredSkill* requiredSkill in skill.requiredSkills)
		[self addSkill:requiredSkill];
}

@end
