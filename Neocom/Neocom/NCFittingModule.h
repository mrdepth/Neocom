//
//  NCFittingModule.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingItem.h"


@class NCFittingCharge, NCFittingShip;
@interface NCFittingModule : NCFittingItem
@property (readonly) NCFittingModuleSlot slot;
@property (readonly) NCFittingModuleHardpoint hardpoint;
@property (readonly) NCFittingModuleState state;
@property (nonatomic, assign) NCFittingModuleState preferredState;
- (BOOL) canHaveState:(NCFittingModuleState) state;

@property (nonatomic, strong, nullable) NCFittingCharge* charge;
@property (readonly, nonnull) NSIndexSet* chargeGroups;
@property (readonly) NSInteger chargeSize;

@property (readonly) BOOL requireTarget;
@property (nonatomic, strong, nullable) NCFittingShip* target;

@property (readonly) double reloadTime;
@property (readonly) double cycleTime;
@property (readonly) double rawCycleTime;
@property (nonatomic, assign) BOOL factorReload;
@property (readonly) NSInteger charges;
@property (readonly) NSInteger shots;
@property (readonly) NSInteger capUse;

@property (readonly) NCFittingDamage dps;
@property (readonly) NCFittingDamage volley;
- (NCFittingDamage) dpsWithTarget:(NCFittingHostileTarget) target NS_SWIFT_NAME(dps(target:));
@property (readonly) double maxRange;
@property (readonly) double falloff;
@property (readonly) double accuracyScore;
@property (readonly) double signatureResolution;
@property (readonly) double lifeTime;
@property (readonly) BOOL isEnabled;

- (double) angularVelocityWithTargetSignature:(double) targetSignature NS_SWIFT_NAME(angularVelocity(targetSignature:));


@end
