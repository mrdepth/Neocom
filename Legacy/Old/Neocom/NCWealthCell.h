//
//  NCWealthCell.h
//  Neocom
//
//  Created by Артем Шиманский on 19.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCPieChartView.h"

@interface NCWealthCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet NCPieChartView *pieChartView;

@end
