//
//  NCFittingProtected.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#ifndef NCFittingProtected_h
#define NCFittingProtected_h

#import <Dgmpp/Dgmpp.h>
#import "NCFittingEngine.h"
#import "NCFittingItem.h"
#import "NCFittingAttribute.h"
#import "NCFittingCharacter.h"
#import "NCFittingGang.h"
#import "NCFittingSkill.h"
#import "NCFittingImplant.h"
#import "NCFittingBooster.h"
#import "NCFittingShip.h"
#import "NCFittingModule.h"
#import "NCFittingCharge.h"
#import "NCFittingDrone.h"

#import "NCFittingPlanet.h"
#import "NCFittingFacility.h"
#import "NCFittingRoute.h"
#import "NCFittingCommodity.h"
#import "NCFittingCommandCenter.h"
#import "NCFittingStorageFacility.h"
#import "NCFittingExtractorControlUnit.h"
#import "NCFittingIndustryFacility.h"
#import "NCFittingSpaceport.h"
#import "NCFittingSchematic.h"
#import "NCFittingCycle.h"
#import "NCFittingProductionCycle.h"
#import "NCFittingState.h"
#import "NCFittingProductionState.h"
#import "NCFittingStructure.h"

#if DEBUG
#define NCVerifyFittingContext(engine) ([engine verifyContext])
#else
#define NCVerifyFittingContext(engine)
#endif

@interface NCFittingItem()
@property (nonatomic, assign) std::shared_ptr<dgmpp::Item> item;

//- (nonnull instancetype) initWithItem:(std::shared_ptr<dgmpp::Item> const&) item engine:(nonnull NCFittingEngine*) engine;
+ (nullable instancetype) item:(std::shared_ptr<dgmpp::Item> const&) item withEngine:(nonnull NCFittingEngine*) engine;

@end

@interface NCFittingAttribute()
- (nonnull instancetype) initWithAttribute:(std::shared_ptr<dgmpp::Attribute> const&) attribute engine:(nonnull NCFittingEngine*) engine;
@end

@interface NCFittingEngine()
@property (nonatomic, assign) std::shared_ptr<dgmpp::Engine> engine;

- (void) updateWithItem:(nullable NCFittingItem*) item;
#if DEBUG
- (void) verifyContext;
#endif
@end


@interface NCFittingPlanet()
@property (nonatomic, assign) std::shared_ptr<dgmpp::Planet> planet;
- (nonnull instancetype) initWithPlanet:(std::shared_ptr<dgmpp::Planet> const&) planet engine:(nonnull NCFittingEngine*) engine;
@end

@interface NCFittingFacility()
@property (nonatomic, assign) std::shared_ptr<dgmpp::Facility> facility;
+ (nullable instancetype) facility:(std::shared_ptr<dgmpp::Facility> const&) facility withEngine:(nonnull NCFittingEngine*) engine;
@end

@interface NCFittingRoute()
@property (nonatomic, assign) std::shared_ptr<const dgmpp::Route> route;
- (nonnull instancetype) initWithRoute:(std::shared_ptr<const dgmpp::Route> const&) route engine:(nonnull NCFittingEngine*) engine;
@end

@interface NCFittingCommodity()
@property (nonatomic, assign) std::shared_ptr<dgmpp::Commodity> commodity;
- (nonnull instancetype) initWithCommodity:(dgmpp::Commodity) commodity engine:(nonnull NCFittingEngine*) engine;
@end

@interface NCFittingSchematic()
@property (nonatomic, assign) std::shared_ptr<dgmpp::Schematic> schematic;
- (nonnull instancetype) initWithSchematic:(std::shared_ptr<dgmpp::Schematic> const&) schematic engine:(nonnull NCFittingEngine*) engine;
@end

@interface NCFittingCycle()
@property (nonatomic, assign) std::shared_ptr<dgmpp::Cycle> cycle;
+ (nullable instancetype) cycle:(std::shared_ptr<dgmpp::Cycle> const&) cycle withEngine:(nonnull NCFittingEngine*) engine;
@end

@interface NCFittingState()
@property (nonatomic, assign) std::shared_ptr<dgmpp::State> state;
+ (nullable instancetype) state:(std::shared_ptr<dgmpp::State> const&) state withEngine:(nonnull NCFittingEngine*) engine;
@end

#endif /* NCFittingProtected_h */
