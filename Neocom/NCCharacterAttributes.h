//
//  NCCharacterAttributes.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EVEDBInvType;
@class EVECharacterSheet;
@interface NCCharacterAttributes : NSObject
@property (nonatomic, assign) NSInteger intelligence;
@property (nonatomic, assign) NSInteger memory;
@property (nonatomic, assign) NSInteger charisma;
@property (nonatomic, assign) NSInteger perception;
@property (nonatomic, assign) NSInteger willpower;

+ (instancetype) defaultCharacterAttributes;
- (id) initWithCharacterSheet:(EVECharacterSheet*) characterSheet;
- (float) skillpointsPerSecondForSkill:(EVEDBInvType*) skill;

@end