//
//  POSFit.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 28.01.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Fit.h"

#include "eufe.h"

@class EVEAssetListItem;

@interface POSFit : Fit

@property (nonatomic, assign) eufe::ControlTower* controlTower;

//CoreData
@property (nonatomic, strong) NSString * structures;

+ (id) posFitWithFitName:(NSString*) fitName controlTower:(eufe::ControlTower*) aControlTower;
+ (id) posFitWithAsset:(EVEAssetListItem*) asset engine:(eufe::Engine*) engine;

+ (NSArray*) allFits;

- (id) initWithFitName:(NSString*) aFitName controlTower:(eufe::ControlTower*) aControlTower;
- (id) initWithAsset:(EVEAssetListItem*) asset engine:(eufe::Engine*) engine;

@end
