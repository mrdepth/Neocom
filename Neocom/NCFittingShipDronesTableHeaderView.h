//
//  NCFittingShipDronesTableHeaderView.h
//  Neocom
//
//  Created by Shimanski Artem on 06.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCProgressLabel.h"

@interface NCFittingShipDronesTableHeaderView : UIView
@property (nonatomic, weak) IBOutlet NCProgressLabel *droneBayLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *droneBandwidthLabel;
@property (nonatomic, weak) IBOutlet UILabel *dronesCountLabel;
@end
