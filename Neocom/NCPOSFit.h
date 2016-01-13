//
//  NCPOSFit.h
//  Neocom
//
//  Created by Артем Шиманский on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCLoadout.h"
#import <dgmpp/dgmpp.h>
#import "NCFittingEngine.h"

@interface NCLoadoutDataPOS: NSObject<NSCoding>
@property (nonatomic, strong) NSArray* structures;
@end

@interface NCLoadoutDataPOSStructure : NSObject<NSCoding>
@property (nonatomic, assign) dgmpp::TypeID typeID;
@property (nonatomic, assign) dgmpp::TypeID chargeID;
@property (nonatomic, assign) dgmpp::Module::State state;
@property (nonatomic, assign) int count;
@end

@class EVEAssetListItem;
@interface NCPOSFit : NSObject
@property (nonatomic, strong) NSString* loadoutName;
@property (nonatomic, assign, readonly) int32_t typeID;

@property (nonatomic, strong, readonly) NCFittingEngine* engine;

//Import
@property (nonatomic, strong, readonly) NSManagedObjectID* loadoutID;
@property (nonatomic, strong, readonly) EVEAssetListItem* asset;

- (id) initWithLoadout:(NCLoadout*) loadout;
- (id) initWithType:(NCDBInvType*) type;
- (id) initWithAsset:(EVEAssetListItem*) asset;

- (void) save;
- (void) duplicateWithCompletioBloc:(void(^)()) completionBlock;

@end
