//
//  POSFuelCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface POSFuelCellView : UITableViewCell
@property (nonatomic, retain) IBOutlet UILabel *typeNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *remainsLabel;
@property (nonatomic, retain) IBOutlet UILabel *consumptionLabel;
@property (nonatomic, retain) IBOutlet UIImageView *iconImageView;
@end
