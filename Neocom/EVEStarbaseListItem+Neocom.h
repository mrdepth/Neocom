//
//  EVEStarbaseListItem+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEStarbaseList.h"

@class EVEStarbaseDetail;
@class EVEDBInvType;
@class EVEDBMapSolarSystem;
@class EVEDBMapDenormalize;
@interface EVEStarbaseListItem (Neocom)
@property (nonatomic, strong) EVEStarbaseDetail* details;
@property (nonatomic, assign) float resourceConsumptionBonus;
@property (nonatomic, strong) EVEDBMapSolarSystem* solarSystem;
@property (nonatomic, strong) EVEDBMapDenormalize* moon;
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, strong) NSString* title;
@end
