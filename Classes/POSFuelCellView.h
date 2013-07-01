//
//  POSFuelCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface POSFuelCellView : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *typeNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *remainsLabel;
@property (nonatomic, weak) IBOutlet UILabel *consumptionLabel;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@end
