//
//  POSFuelCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GroupedCell.h"


@interface POSFuelCellView : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel *typeNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *remainsLabel;
@property (nonatomic, weak) IBOutlet UILabel *consumptionLabel;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@end
