//
//  NCFittingCharacter.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingItem.h"

@class NCFittingSkill, NCFittingImplant, NCFittingBooster;
@interface NCFittingSkills<NSFastEnumeration> : NSObject
- (nullable NCFittingSkill*) objectAtIndexedSubscript:(NSInteger) typeID;
@end

@interface NCFittingImplants : NSObject
- (nullable NCFittingImplant*) objectAtIndexedSubscript:(NSInteger) slot;
@end

@interface NCFittingBoosters : NSObject
- (nullable NCFittingBooster*) objectAtIndexedSubscript:(NSInteger) slot;
@end

@class NCFittingShip;
@interface NCFittingCharacter : NCFittingItem
@property (nonatomic, nullable) NCFittingShip* ship;
@property (readonly, nonnull) NCFittingSkills* skills;
@property (readonly, nonnull) NCFittingImplants* implants;
@property (readonly, nonnull) NCFittingBoosters* boosters;

- (nullable NCFittingImplant*) addImplant:(NSInteger) typeID;
- (nullable NCFittingImplant*) addImplant:(NSInteger) typeID forced:(BOOL) forced;
- (void) removeImplant:(nonnull NCFittingImplant*) implant;
- (nullable NCFittingBooster*) addBooster:(NSInteger) typeID;
- (nullable NCFittingBooster*) addBooster:(NSInteger) typeID forced:(BOOL) forced;
- (void) removeBooster:(nonnull NCFittingBooster*) booster;
@end
