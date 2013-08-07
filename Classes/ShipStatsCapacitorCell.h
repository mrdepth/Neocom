//
//  ShipStatsCapacitorCell.h
//  EVEUniverse
//
//  Created by mr_depth on 07.08.13.
//
//

#import "GroupedCell.h"

@interface ShipStatsCapacitorCell : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel *capacitorCapacityLabel;
@property (nonatomic, weak) IBOutlet UILabel *capacitorStateLabel;
@property (nonatomic, weak) IBOutlet UILabel *capacitorRechargeTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *capacitorDeltaLabel;

@end
