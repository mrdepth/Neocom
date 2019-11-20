//
//  NCFittingShipFirepowerCell.h
//  Neocom
//
//  Created by Артем Шиманский on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCFittingShipFirepowerCell : NCTableViewCell
@property (nonatomic, weak) IBOutlet UILabel *weaponDPSLabel;
@property (nonatomic, weak) IBOutlet UILabel *droneDPSLabel;
@property (nonatomic, weak) IBOutlet UILabel *volleyDamageLabel;
@property (nonatomic, weak) IBOutlet UILabel *dpsLabel;

@end
