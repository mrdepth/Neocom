//
//  EVEStarbaseListItem+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEStarbaseList.h"

@class EVEStarbaseDetail;
@class NCDBInvType;
@class NCDBMapSolarSystem;
@class NCDBMapDenormalize;
@interface EVEStarbaseListItem (Neocom)
@property (nonatomic, strong) EVEStarbaseDetail* details;
@property (nonatomic, assign) float resourceConsumptionBonus;
@property (nonatomic, strong) NCDBMapSolarSystem* solarSystem;
@property (nonatomic, strong) NCDBMapDenormalize* moon;
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, strong) NSString* title;
@end
