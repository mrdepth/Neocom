//
//  NCSkill.h
//  Develop
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NCSkillTimeConstantAttributeID 275

@class NCDBInvType, NCCharacterAttributes;
@interface NCSkill : NSObject
@property (nonatomic, assign, readonly) int32_t typeID;
@property (nonatomic, copy, readonly) NSString* typeName;
@property (nonatomic, assign, readonly) int32_t primaryAttributeID;
@property (nonatomic, assign, readonly) int32_t secondaryAttributeID;
@property (nonatomic, assign, readonly) int32_t rank;
@property (nonatomic, assign) int32_t skillPoints;
@property (nonatomic, assign) int32_t level;
@property (nonatomic, strong) NSDate* trainingStartDate;

- (id) initWithInvType:(NCDBInvType*) type;
- (NSTimeInterval) trainingTimeToLevelUpWithCharacterAttributes:(NCCharacterAttributes*) attributes;

@end
