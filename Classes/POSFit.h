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
	NSInteger fitID;
	NSString* fitName;
}

+ (id) posFitWithFitID:(NSInteger) fitID fitName:(NSString*) fitName controlTower:(boost::shared_ptr<eufe::ControlTower>) aControlTower;
+ (id) posFitWithDictionary:(NSDictionary*) dictionary engine:(eufe::Engine*) engine;
+ (id) posFitWithAsset:(EVEAssetListItem*) asset engine:(eufe::Engine*) engine;

- (id) initWithFitID:(NSInteger) aFitID fitName:(NSString*) aFitName controlTower:(boost::shared_ptr<eufe::ControlTower>) aControlTower;
- (id) initWithDictionary:(NSDictionary*) dictionary engine:(eufe::Engine*) engine;
- (id) initWithAsset:(EVEAssetListItem*) asset engine:(eufe::Engine*) engine;
- (NSDictionary*) dictionary;

@property (nonatomic, assign) NSInteger fitID;
@property (nonatomic, copy) NSString* fitName;
@property (nonatomic, readonly) boost::shared_ptr<eufe::ControlTower> controlTower;

- (void) save;

@end
