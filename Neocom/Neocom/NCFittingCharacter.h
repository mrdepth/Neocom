//
//  NCFittingCharacter.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingItem.h"

@class NCFittingSkill, NCFittingImplant, NCFittingBooster;
@interface NCFittingSkills: NSObject
@property (readonly) NSUInteger count;
@property (readonly, nonnull) NSArray<NCFittingSkill*>* all;
- (nullable NCFittingSkill*) objectAtIndexedSubscript:(NSInteger) typeID;


@end

@interface NCFittingImplants : NSObject<NSFastEnumeration>
@property (readonly) NSUInteger count;
- (nullable NCFittingImplant*) objectAtIndexedSubscript:(NSInteger) slot;
@end

@interface NCFittingBoosters : NSObject<NSFastEnumeration>
@property (readonly) NSUInteger count;
- (nullable NCFittingBooster*) objectAtIndexedSubscript:(NSInteger) slot;
@end

@class NCFittingShip;
@interface NCFittingCharacter : NCFittingItem
@property (nonatomic, nullable) NCFittingShip* ship;
@property (readonly, nonnull) NCFittingSkills* skills;
@property (readonly, nonnull) NCFittingImplants* implants;
@property (readonly, nonnull) NCFittingBoosters* boosters;

- (nullable NCFittingImplant*) addImplantWithTypeID:(NSInteger) typeID NS_SWIFT_NAME(addImplant(typeID:));
- (nullable NCFittingImplant*) addImplantWithTypeID:(NSInteger) typeID forced:(BOOL) forced NS_SWIFT_NAME(addImplant(typeID:forced:));
- (void) removeImplant:(nonnull NCFittingImplant*) implant;
- (nullable NCFittingBooster*) addBoosterWithTypeID:(NSInteger) typeID NS_SWIFT_NAME(addBooster(typeID:));
- (nullable NCFittingBooster*) addBoosterWithTypeID:(NSInteger) typeID forced:(BOOL) forced NS_SWIFT_NAME(addBooster(typeID:forced:));
- (void) removeBooster:(nonnull NCFittingBooster*) booster;
@end
