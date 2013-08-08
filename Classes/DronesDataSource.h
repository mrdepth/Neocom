//
//  DronesDataSource.h
//  EVEUniverse
//
//  Created by mr_depth on 03.08.13.
//
//

#import "FittingDataSource.h"
#import "ProgressLabel.h"

@interface DronesDataSource : FittingDataSource
@property (nonatomic, weak) IBOutlet ProgressLabel *droneBayLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *droneBandwidthLabel;
@property (nonatomic, weak) IBOutlet UILabel *dronesCountLabel;

@end
