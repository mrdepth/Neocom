//
//  ShipStatsTankCell.h
//  EVEUniverse
//
//  Created by mr_depth on 07.08.13.
//
//

#import "GroupedCell.h"

@interface ShipStatsTankCell : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel *categoryLabel;
@property (nonatomic, weak) IBOutlet UILabel *shieldRecharge;
@property (nonatomic, weak) IBOutlet UILabel *shieldBoost;
@property (nonatomic, weak) IBOutlet UILabel *armorRepair;
@property (nonatomic, weak) IBOutlet UILabel *hullRepair;
@end
