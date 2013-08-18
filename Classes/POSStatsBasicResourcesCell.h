//
//  POSStatsBasicResourcesCell.h
//  EVEUniverse
//
//  Created by mr_depth on 16.08.13.
//
//

#import "GroupedCell.h"
#import "ProgressLabel.h"

@interface POSStatsBasicResourcesCell : GroupedCell
@property (nonatomic, weak) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *cpuLabel;

@end
