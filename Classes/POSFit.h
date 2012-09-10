//
//  POSFit.h
//  EVEUniverse
//
//  Created by Mr. Depth on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ItemInfo.h"

#include "eufe.h"

@class EVEAssetListItem;
@interface POSFit : ItemInfo {
	NSString* fitID;
	NSString* fitName;
}

+ (id) posFitWithFitID:(NSString*) fitID fitName:(NSString*) fitName controlTower:(eufe::ControlTower*) aControlTower;
+ (id) posFitWithDictionary:(NSDictionary*) dictionary engine:(eufe::Engine*) engine;
+ (id) posFitWithAsset:(EVEAssetListItem*) asset engine:(eufe::Engine*) engine;

- (id) initWithFitID:(NSString*) aFitID fitName:(NSString*) aFitName controlTower:(eufe::ControlTower*) aControlTower;
- (id) initWithDictionary:(NSDictionary*) dictionary engine:(eufe::Engine*) engine;
- (id) initWithAsset:(EVEAssetListItem*) asset engine:(eufe::Engine*) engine;
- (NSDictionary*) dictionary;

@property (nonatomic, copy) NSString* fitID;
@property (nonatomic, copy) NSString* fitName;
@property (nonatomic, readonly) eufe::ControlTower* controlTower;

- (void) save;

@end
