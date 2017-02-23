//
//  NCFittingEngine.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCFittingGang.h"
#import "NCFittingCharacter.h"
#import "NCFittingSkill.h"
#import "NCFittingImplant.h"
#import "NCFittingBooster.h"
#import "NCFittingShip.h"
#import "NCFittingModule.h"
#import "NCFittingDrone.h"
#import "NCFittingCharge.h"
#import "NCFittingAttribute.h"
#import "NCFittingArea.h"

extern _Nonnull NSNotificationName const NCFittingEngineDidUpdateNotification;

@interface NCFittingEngine : NSObject
@property (readonly, nonnull) NCFittingGang* gang;
@property (nonatomic, strong, nullable) NCFittingArea* area;

- (nonnull instancetype) init NS_DESIGNATED_INITIALIZER;
- (void) performBlock:(nonnull void(^)()) block;
- (void) performBlockAndWait:(nonnull void(^)()) block;

- (void) assignIdentifier:(nullable NSString*) identifier forItem:(nonnull NCFittingItem*) item NS_SWIFT_NAME(assign(identifier:for:));
- (nullable NSString*) identifierForItem:(nonnull NCFittingItem*) item NS_SWIFT_NAME(identifier(for:));

@end
