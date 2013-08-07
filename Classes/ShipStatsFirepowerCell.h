//
//  ShipStatsFirepowerCell.h
//  EVEUniverse
//
//  Created by mr_depth on 07.08.13.
//
//

#import "GroupedCell.h"

@interface ShipStatsFirepowerCell : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel *weaponDPSLabel;
@property (nonatomic, weak) IBOutlet UILabel *droneDPSLabel;
@property (nonatomic, weak) IBOutlet UILabel *volleyDamageLabel;
@property (nonatomic, weak) IBOutlet UILabel *dpsLabel;

@end
