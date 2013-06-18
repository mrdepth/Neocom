//
//  DamagePattern.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EVEDBInvType;
@interface DamagePattern : NSObject<NSCoding>
@property (nonatomic, assign) float emAmount;
@property (nonatomic, assign) float thermalAmount;
@property (nonatomic, assign) float kineticAmount;
@property (nonatomic, assign) float explosiveAmount;
@property (nonatomic, copy) NSString* patternName;
@property (nonatomic, copy) NSString* uuid;

+ (id) uniformDamagePattern;
+ (id) damagePatternWithNPCType:(EVEDBInvType*) type;
- (id) initWithNPCType:(EVEDBInvType*) type;

@end
