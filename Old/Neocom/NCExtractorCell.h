//
//  NCExtractorCell.h
//  Neocom
//
//  Created by Артем Шиманский on 26.01.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCBarChartView.h"

@interface NCExtractorCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NCBarChartView *barChartView;
@property (weak, nonatomic) IBOutlet UILabel *axisYLabel;
@property (weak, nonatomic) IBOutlet UILabel *axisXLabel;
@property (weak, nonatomic) IBOutlet UILabel *markerLabel;
@property (weak, nonatomic) IBOutlet UIView *markerAuxiliaryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *markerAuxiliaryViewConstraint;

@property (weak, nonatomic) IBOutlet UILabel *productLabel;
@property (weak, nonatomic) IBOutlet UILabel *sumLabel;
@property (weak, nonatomic) IBOutlet UILabel *yieldLabel;
@property (weak, nonatomic) IBOutlet UILabel *cycleTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentCycleLabel;
@property (weak, nonatomic) IBOutlet UILabel *wasteTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *wasteLabel;
@property (weak, nonatomic) IBOutlet UILabel *wasteTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *expiredLabel;

@end
