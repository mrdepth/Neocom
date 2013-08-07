//
//  EVEDBCrtCertificate+State.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EVEDBCrtCertificate+State.h"
#import "EVEAccount.h"
#import <objc/runtime.h>

@implementation EVEDBCrtCertificate (State)

- (EVEDBCrtCertificateState) state {
	NSNumber* state = objc_getAssociatedObject(self, @"state");
	NSNumber* characterID = objc_getAssociatedObject(self, @"characterID");
	EVEAccount* account = [EVEAccount currentAccount];
	if (!state || [characterID integerValue] != account.character.characterID) {
		if (!account || !account.characterSheet) {
			state = @(EVEDBCrtCertificateStateNotLearned);
			characterID = nil;
		}
		else {
			BOOL learned = YES;
			BOOL notLearned = YES;
			for (EVEDBCrtRelationship* relationship in self.prerequisites) {
				if (relationship.parentTypeID) {
					EVECharacterSheetSkill* skill = account.characterSheet.skillsMap[@(relationship.parentTypeID)];
					if (!skill)
						learned = NO;
					else if (skill.level < relationship.parentLevel) {
						learned = NO;
						notLearned = NO;
					}
					else
						notLearned = NO;
					if (!learned && !notLearned)
						break;
				}
				else if (relationship.parent) {
					switch (relationship.parent.state) {
						case EVEDBCrtCertificateStateLearned:
							notLearned = NO;
							break;
						case EVEDBCrtCertificateStateNotLearned:
							learned = NO;
							break;
						default:
							learned = NO;
							notLearned = NO;
							break;
					}
				}
			}
			if (learned && !notLearned)
				state = @(EVEDBCrtCertificateStateLearned);
			else if (!learned && notLearned)
				state = @(EVEDBCrtCertificateStateNotLearned);
			else
				state = @(EVEDBCrtCertificateStateLowLevel);
		}
		
		objc_setAssociatedObject(self, @"state", state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		objc_setAssociatedObject(self, @"characterID", characterID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return (EVEDBCrtCertificateState) [state integerValue];
}

- (NSString*) stateIconImageName {
	switch (self.state) {
		case EVEDBCrtCertificateStateLearned:
			return @"Icons/icon38_193.png";
		case EVEDBCrtCertificateStateNotLearned:
			return @"Icons/icon38_194.png";
		default:
			return @"Icons/icon38_195.png";
	}
}

@end
