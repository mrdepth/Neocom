//
//  EVECentralQuickLookOrder+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 19.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <EVEAPI/EVEAPI.h>

@class NCDBMapRegion;
@class NCDBStaStation;
@interface EVECentralQuickLookOrder (Neocom)

@property (nonatomic, strong) NCDBMapRegion* region;
@property (nonatomic, strong) NCDBStaStation* station;


@end
