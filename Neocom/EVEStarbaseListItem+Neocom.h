//
//  EVEStarbaseListItem+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <EVEAPI/EVEAPI.h>

@class EVEStarbaseDetail;
@class NCDBMapSolarSystem;
@interface EVEStarbaseListItem (Neocom)
@property (nonatomic, strong) EVEStarbaseDetail* details;
@property (nonatomic, assign) float resourceConsumptionBonus;
@property (nonatomic, strong) NCDBMapSolarSystem* solarSystem;
@property (nonatomic, strong) NSString* title;
@end
