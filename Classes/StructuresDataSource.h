//
//  StructuresDataSource.h
//  EVEUniverse
//
//  Created by mr_depth on 14.08.13.
//
//

#import "POSFittingDataSource.h"
#import "ProgressLabel.h"

@interface StructuresDataSource : POSFittingDataSource
@property (nonatomic, weak) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *cpuLabel;

@end
