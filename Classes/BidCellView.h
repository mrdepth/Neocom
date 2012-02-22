//
//  BidCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BidCellView : UITableViewCell {
	UILabel *characterNameLabel;
	UILabel *dateLabel;
	UILabel *amountLabel;
}
@property (nonatomic, retain) IBOutlet UILabel *characterNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *dateLabel;
@property (nonatomic, retain) IBOutlet UILabel *amountLabel;

@end
