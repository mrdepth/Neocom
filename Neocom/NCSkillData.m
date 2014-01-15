//
//  NCSkillData.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillData.h"
#import "NCCharacterAttributes.h"
#import "EVEDBInvType+Neocom.h"

@implementation NCSkillData

- (NSTimeInterval) trainingTimeWithCharacterAttributes:(NCCharacterAttributes*) attributes {
	return self.targetSkillPoints > self.skillPoints ? (self.targetSkillPoints - self.skillPoints) / [attributes skillpointsPerSecondForSkill:self] : 0.0;
}

- (void) setTargetLevel:(NSInteger)targetLevel {
	_targetLevel = targetLevel;
	_targetSkillPoints = [self skillPointsAtLevel:targetLevel];
}

@end
