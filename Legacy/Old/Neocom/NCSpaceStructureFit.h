//
//  NCSpaceStructureFit.h
//  Neocom
//
//  Created by Артем Шиманский on 14.03.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCLoadout.h"
#import "NCFitCharacter.h"
#import "NCFittingEngine.h"

@interface NCLoadoutDataSpaceStructure : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* hiSlots;
@property (nonatomic, strong) NSArray* medSlots;
@property (nonatomic, strong) NSArray* lowSlots;
@property (nonatomic, strong) NSArray* rigSlots;
@property (nonatomic, strong) NSArray* services;
@property (nonatomic, strong) NSArray* drones;

@end

@interface NCLoadoutDataSpaceStructureModule : NSObject<NSCoding>
@property (nonatomic, assign) dgmpp::TypeID typeID;
@property (nonatomic, assign) dgmpp::TypeID chargeID;
@property (nonatomic, assign) dgmpp::Module::State state;
@end

@interface NCLoadoutDataSpaceStructureDrone : NSObject<NSCoding>
@property (nonatomic, assign) dgmpp::TypeID typeID;
@property (nonatomic, assign) int32_t count;
@property (nonatomic, assign) bool active;
@end

@class NCDBInvType;
@interface NCSpaceStructureFit : NSObject
@property (nonatomic, strong) NSString* loadoutName;
@property (nonatomic, assign, readonly) int32_t typeID;

@property (nonatomic, strong, readonly) NCFittingEngine* engine;
@property (nonatomic, assign, readonly) std::shared_ptr<dgmpp::Character> pilot;
@property (nonatomic, strong, readonly) NCFitCharacter* character;

//Import
@property (nonatomic, strong, readonly) NSManagedObjectID* loadoutID;

- (id) initWithLoadout:(NCLoadout*) loadout;
- (id) initWithType:(NCDBInvType*) type;
- (void) setCharacter:(NCFitCharacter*) character withCompletionBlock:(void(^)()) completionBlock;

- (void) flush;
- (void) save;
- (void) duplicateWithCompletioBloc:(void(^)()) completionBlock;

@end
