//
//  NCShipFit.h
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCLoadout.h"
#import "NCFitCharacter.h"
#import "NCFittingEngine.h"

@interface NCLoadoutDataShip : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* hiSlots;
@property (nonatomic, strong) NSArray* medSlots;
@property (nonatomic, strong) NSArray* lowSlots;
@property (nonatomic, strong) NSArray* rigSlots;
@property (nonatomic, strong) NSArray* subsystems;
@property (nonatomic, strong) NSArray* drones;
@property (nonatomic, strong) NSArray* cargo;
@property (nonatomic, strong) NSArray* implants;
@property (nonatomic, strong) NSArray* boosters;
@property (nonatomic, assign) dgmpp::TypeID mode;

@end

@interface NCLoadoutDataShipModule : NSObject<NSCoding>
@property (nonatomic, assign) dgmpp::TypeID typeID;
@property (nonatomic, assign) dgmpp::TypeID chargeID;
@property (nonatomic, assign) dgmpp::Module::State state;
@end

@interface NCLoadoutDataShipDrone : NSObject<NSCoding>
@property (nonatomic, assign) dgmpp::TypeID typeID;
@property (nonatomic, assign) int32_t count;
@property (nonatomic, assign) bool active;
@end

@interface NCLoadoutDataShipImplant : NSObject<NSCoding>
@property (nonatomic, assign) dgmpp::TypeID typeID;
@end

@interface NCLoadoutDataShipBooster : NSObject<NSCoding>
@property (nonatomic, assign) dgmpp::TypeID typeID;
@end

@interface NCLoadoutDataShipCargoItem : NSObject<NSCoding>
@property (nonatomic, assign) dgmpp::TypeID typeID;
@property (nonatomic, assign) int32_t count;
@end

@class BCEveLoadout;
@class NAPISearchItem;
@class EVEAssetListItem;
@class NCKillMail;
@class NCDBInvType;
@class CRFitting;
@interface NCShipFit : NSObject
@property (nonatomic, strong) NSString* loadoutName;
@property (nonatomic, assign, readonly) int32_t typeID;

@property (nonatomic, strong, readonly) NCFittingEngine* engine;
@property (nonatomic, assign, readonly) std::shared_ptr<dgmpp::Character> pilot;
@property (nonatomic, strong, readonly) NCFitCharacter* character;

//Import
@property (nonatomic, strong, readonly) NSManagedObjectID* loadoutID;
@property (nonatomic, strong, readonly) NAPISearchItem* apiLadout;
@property (nonatomic, strong, readonly) EVEAssetListItem* asset;
@property (nonatomic, strong, readonly) NCKillMail* killMail;
@property (nonatomic, strong, readonly) NSString* dna;
@property (nonatomic, strong, readonly) CRFitting* crFitting;

//Export
@property (nonatomic, readonly) NSString* canonicalName;
@property (nonatomic, readonly) NSString* dnaRepresentation;
@property (nonatomic, readonly) NSString* eveXMLRepresentation;
@property (nonatomic, readonly) NSString* eveXMLRecordRepresentation;
@property (nonatomic, readonly) NSString* eftRepresentation;
@property (nonatomic, readonly) NSString* hyperlinkTag;
@property (nonatomic, readonly) CRFitting* crFittingRepresentation;

- (id) initWithLoadout:(NCLoadout*) loadout;
- (id) initWithType:(NCDBInvType*) type;
- (id) initWithAPILoadout:(NAPISearchItem*) apiLoadout;
- (id) initWithAsset:(EVEAssetListItem*) asset;
- (id) initWithKillMail:(NCKillMail*) killMail;
- (id) initWithDNA:(NSString*) dna;
- (id) initWithCRFitting:(CRFitting*) fitting;
- (void) setCharacter:(NCFitCharacter*) character withCompletionBlock:(void(^)()) completionBlock;

- (void) flush;
- (void) save;
- (void) duplicateWithCompletioBloc:(void(^)()) completionBlock;

@end
