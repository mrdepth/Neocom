//
//  NCShipFit.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NCFit.h"


@interface NCShipFit : NCFit

@property (nonatomic, retain) NSString * boosters;
@property (nonatomic, retain) NSString * cargo;
@property (nonatomic, retain) NSString * drones;
@property (nonatomic, retain) NSString * hiSlots;
@property (nonatomic, retain) NSString * implants;
@property (nonatomic, retain) NSString * lowSlots;
@property (nonatomic, retain) NSString * medSlots;
@property (nonatomic, retain) NSString * rigSlots;
@property (nonatomic, retain) NSString * subsystems;

@end
