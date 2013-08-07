//
//  ShipStatsBasicResourcesCell.h
//  EVEUniverse
//
//  Created by mr_depth on 07.08.13.
//
//

#import "GroupedCell.h"
#import "ProgressLabel.h"

@interface ShipStatsBasicResourcesCell : GroupedCell
@property (nonatomic, weak) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *cpuLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *droneBayLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *droneBandwidthLabel;

@end
