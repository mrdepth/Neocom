//
//  NCFittingDrone.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingItem.h"

@class NCFittingShip, NCFittingCharge;
@interface NCFittingDrone : NCFittingItem
@property (readonly) NCFittingFighterSquadron squadron;
@property (readonly) NSInteger squadronSize;
@property (nonatomic, strong, nullable) NCFittingShip* target;
@property (readonly) BOOL dealsDamage;
@property (readonly, nullable) NCFittingCharge* charge;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) NSInteger squadronTag;

@property (readonly) double cycleTime;
@property (readonly) NCFittingDamage dps;
@property (readonly) NCFittingDamage volley;
- (NCFittingDamage) dpsWithTarget:(NCFittingHostileTarget) target NS_SWIFT_NAME(dps(target:));
@property (readonly) double maxRange;
@property (readonly) double falloff;
@property (readonly) double accuracyScore;
@property (readonly) double velocity;
@property (readonly) double miningYield;

@end
