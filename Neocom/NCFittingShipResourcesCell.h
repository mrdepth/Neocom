//
//  NCFittingShipResourcesCell.h
//  Neocom
//
//  Created by Артем Шиманский on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCProgressLabel.h"

@interface NCFittingShipResourcesCell : NCTableViewCell
@property (nonatomic, weak) IBOutlet NCProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *cpuLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *droneBayLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *droneBandwidthLabel;

@end
