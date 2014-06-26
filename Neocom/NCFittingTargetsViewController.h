//
//  NCFittingTargetsViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 03.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "eufe.h"

@class NCShipFit;
@interface NCFittingTargetsViewController : NCTableViewController
@property (nonatomic, strong) NSArray* items;
@property (nonatomic, strong) NSArray* targets;
@property (nonatomic, strong) NCShipFit* selectedTarget;

@end
