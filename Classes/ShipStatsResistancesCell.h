//
//  ShipStatsResistancesCell.h
//  EVEUniverse
//
//  Created by mr_depth on 07.08.13.
//
//

#import "GroupedCell.h"
#import "ProgressLabel.h"

@interface ShipStatsResistancesCell : GroupedCell
@property (nonatomic, weak) IBOutlet UIImageView* categoryImageView;
@property (nonatomic, weak) IBOutlet ProgressLabel *emLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *thermalLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *kineticLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *explosiveLabel;
@property (nonatomic, weak) IBOutlet UILabel* hpLabel;

@end
