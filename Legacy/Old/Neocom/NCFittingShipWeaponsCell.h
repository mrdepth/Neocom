//
//  NCFittingShipWeaponsCell.h
//  Neocom
//
//  Created by Артем Шиманский on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCFittingShipWeaponsCell : NCTableViewCell
@property (nonatomic, weak) IBOutlet UILabel *calibrationLabel;
@property (nonatomic, weak) IBOutlet UILabel *turretsLabel;
@property (nonatomic, weak) IBOutlet UILabel *launchersLabel;
@property (nonatomic, weak) IBOutlet UILabel *dronesLabel;

@end
