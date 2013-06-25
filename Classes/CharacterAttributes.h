//
//  CharacterAttributes.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EVEDBInvType;
@interface CharacterAttributes : NSObject
@property (nonatomic, assign) NSInteger intelligence;
@property (nonatomic, assign) NSInteger memory;
@property (nonatomic, assign) NSInteger charisma;
@property (nonatomic, assign) NSInteger perception;
@property (nonatomic, assign) NSInteger willpower;

+ (CharacterAttributes*) defaultCharacterAttributes;

- (float) skillpointsPerSecondForSkill:(EVEDBInvType*) skill;

@end
