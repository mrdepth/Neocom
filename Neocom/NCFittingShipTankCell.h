//
//  NCFittingShipTankCell.h
//  Neocom
//
//  Created by Артем Шиманский on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCFittingShipTankCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *categoryLabel;
@property (nonatomic, weak) IBOutlet UILabel *shieldRecharge;
@property (nonatomic, weak) IBOutlet UILabel *shieldBoost;
@property (nonatomic, weak) IBOutlet UILabel *armorRepair;
@property (nonatomic, weak) IBOutlet UILabel *hullRepair;

@end
