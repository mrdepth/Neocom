//
//  NCPOSFit.h
//  Neocom
//
//  Created by Артем Шиманский on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCLoadout.h"
#import "eufe.h"

@interface NCLoadoutDataPOS: NSObject<NSCoding>
@property (nonatomic, strong) NSArray* structures;
@end

@interface NCLoadoutDataPOSStructure : NSObject<NSCoding>
@property (nonatomic, assign) eufe::TypeID typeID;
@property (nonatomic, assign) eufe::TypeID chargeID;
@property (nonatomic, assign) eufe::Module::State state;
@property (nonatomic, assign) int count;
@end

@class EVEAssetListItem;
@interface NCPOSFit : NSObject
@property (nonatomic, strong) NCLoadout* loadout;
@property (nonatomic, strong) NSString* loadoutName;
@property (nonatomic, assign) eufe::Engine* engine;
@property (nonatomic, strong) EVEDBInvType* type;

- (id) initWithLoadout:(NCLoadout*) loadout;
- (id) initWithType:(EVEDBInvType*) type;
- (id) initWithAsset:(EVEAssetListItem*) asset;

- (void) save;
- (void) load;

@end
