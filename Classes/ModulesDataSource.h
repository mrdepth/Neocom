//
//  ModulesDataSource.h
//  EVEUniverse
//
//  Created by mr_depth on 02.08.13.
//
//

#import "FittingDataSource.h"
#import "ProgressLabel.h"

@class FittingViewController;
@interface ModulesDataSource : FittingDataSource
@property (nonatomic, weak) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *cpuLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *calibrationLabel;
@property (nonatomic, weak) IBOutlet UILabel *turretsLabel;
@property (nonatomic, weak) IBOutlet UILabel *launchersLabel;

@property (nonatomic, strong) IBOutlet UIView *highSlotsHeaderView;
@property (nonatomic, strong) IBOutlet UIView *medSlotsHeaderView;
@property (nonatomic, strong) IBOutlet UIView *lowSlotsHeaderView;
@property (nonatomic, strong) IBOutlet UIView *rigsSlotsHeaderView;
@property (nonatomic, strong) IBOutlet UIView *subsystemsSlotsHeaderView;

@end
