//
//  NCFittingPOSDefenseOffenseCell.h
//  Neocom
//
//  Created by Shimanski Artem on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCFittingPOSDefenseOffenseCell : NCTableViewCell
@property (nonatomic, weak) IBOutlet UILabel *shieldRecharge;
@property (nonatomic, weak) IBOutlet UILabel *effectiveShieldRecharge;
@property (nonatomic, weak) IBOutlet UILabel *weaponDPSLabel;
@property (nonatomic, weak) IBOutlet UILabel *weaponVolleyLabel;
@end
