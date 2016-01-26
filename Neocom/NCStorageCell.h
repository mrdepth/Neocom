//
//  NCStorageCell.h
//  Neocom
//
//  Created by Артем Шиманский on 26.01.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCProgressLabel.h"
#import "NCBarChartView.h"

@interface NCStorageCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NCProgressLabel *progressLabel;
@property (weak, nonatomic) IBOutlet NCBarChartView *barChartView;
@property (weak, nonatomic) IBOutlet UILabel *axisXLabel;
@property (weak, nonatomic) IBOutlet UILabel *markerLabel;
@property (weak, nonatomic) IBOutlet UIView *markerAuxiliaryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *markerAuxiliaryViewConstraint;
@property (weak, nonatomic) IBOutlet UILabel *materialsLabel;

@end
