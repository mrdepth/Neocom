//
//  POSCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface POSCellView : UITableViewCell {
	UILabel *typeNameLabel;
	UILabel *locationLabel;
	UILabel *stateLabel;
	UILabel *fuelRemainsLabel;
	UIImageView *iconImageView;
	UIImageView *fuelImageView;
}
@property (nonatomic, retain) IBOutlet UILabel *typeNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *locationLabel;
@property (nonatomic, retain) IBOutlet UILabel *stateLabel;
@property (nonatomic, retain) IBOutlet UILabel *fuelRemainsLabel;
@property (nonatomic, retain) IBOutlet UIImageView *iconImageView;
@property (nonatomic, retain) IBOutlet UIImageView *fuelImageView;
@end
