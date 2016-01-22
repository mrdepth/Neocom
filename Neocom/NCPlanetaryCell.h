//
//  NCPlanetaryCell.h
//  Neocom
//
//  Created by Артем Шиманский on 18.01.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCProgressLabel.h"
#import "NCBarChartView.h"

@interface NCPlanetaryCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *productLabel;
@property (weak, nonatomic) IBOutlet NCProgressLabel *progressLabel;
@property (weak, nonatomic) IBOutlet NCBarChartView *barChartView;
@property (weak, nonatomic) IBOutlet UILabel *axisYLabel;
@property (weak, nonatomic) IBOutlet UILabel *axisXLabel;
@property (weak, nonatomic) IBOutlet UIView *markerAuxiliaryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *markerAuxiliaryViewConstraint;
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;
@property (weak, nonatomic) IBOutlet UILabel *materialsLabel;

@end
