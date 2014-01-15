//
//  NCSkillHierarchy.h
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"

@interface EVEDBInvTypeRequiredSkill(NCSkillHierarchy)
@property (nonatomic, assign) NSInteger nestingLevel;
@end

@class NCAccount;
@interface NCSkillHierarchy : NSObject

- (id) initWithRequiredSkill:(EVEDBInvTypeRequiredSkill*) skill account:(NCAccount*) account;

@end
