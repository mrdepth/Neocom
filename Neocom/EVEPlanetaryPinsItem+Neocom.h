//
//  EVEPlanetaryPinsItem+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 25.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "EVEPlanetaryPins.h"

@class NCDBInvType;
@interface EVEPlanetaryPinsItem (Neocom)
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, strong) NCDBInvType* contentType;

@end