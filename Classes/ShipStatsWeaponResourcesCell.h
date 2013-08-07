//
//  ShipStatsWeaponResourcesCell.h
//  EVEUniverse
//
//  Created by mr_depth on 07.08.13.
//
//

#import "GroupedCell.h"

@interface ShipStatsWeaponResourcesCell : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel *calibrationLabel;
@property (nonatomic, weak) IBOutlet UILabel *turretsLabel;
@property (nonatomic, weak) IBOutlet UILabel *launchersLabel;
@property (nonatomic, weak) IBOutlet UILabel *dronesLabel;

@end
