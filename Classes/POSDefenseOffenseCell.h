//
//  POSDefenseOffenseCell.h
//  EVEUniverse
//
//  Created by mr_depth on 16.08.13.
//
//

#import "GroupedCell.h"

@interface POSDefenseOffenseCell : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel *shieldRecharge;
@property (nonatomic, weak) IBOutlet UILabel *weaponDPSLabel;
@end
