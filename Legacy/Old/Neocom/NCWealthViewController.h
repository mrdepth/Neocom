//
//  NCWealthViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 11.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "NCPieChartView.h"

@interface NCWealthViewController : NCTableViewController
@property (weak, nonatomic) IBOutlet NCPieChartView *pieChartView;

@end
