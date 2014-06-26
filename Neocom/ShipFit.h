//
//  ShipFit.h
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "Fit.h"

@interface ShipFit : Fit
@property (nonatomic, strong) NSString * boosters;
@property (nonatomic, strong) NSString * drones;
@property (nonatomic, strong) NSString * implants;
@property (nonatomic, strong) NSString * hiSlots;
@property (nonatomic, strong) NSString * medSlots;
@property (nonatomic, strong) NSString * lowSlots;
@property (nonatomic, strong) NSString * rigSlots;
@property (nonatomic, strong) NSString * subsystems;
@property (nonatomic, strong) NSString * cargo;
@end
