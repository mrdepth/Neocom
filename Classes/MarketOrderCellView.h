//
//  MarketOrderCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MarketOrderCellView : UITableViewCell {
	UILabel *expireInLabel;
	UILabel *stateLabel;
	UILabel *typeNameLabel;
	UILabel *locationLabel;
	UILabel *priceLabel;
	UILabel *qtyLabel;
	UILabel *issuedLabel;
	UILabel *characterLabel;
	UIImageView *iconImageView;
}
@property (nonatomic, retain) IBOutlet UILabel *expireInLabel;
@property (nonatomic, retain) IBOutlet UILabel *stateLabel;
@property (nonatomic, retain) IBOutlet UILabel *typeNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *locationLabel;
@property (nonatomic, retain) IBOutlet UILabel *priceLabel;
@property (nonatomic, retain) IBOutlet UILabel *qtyLabel;
@property (nonatomic, retain) IBOutlet UILabel *issuedLabel;
@property (nonatomic, retain) IBOutlet UILabel *characterLabel;
@property (nonatomic, retain) IBOutlet UIImageView *iconImageView;

@end
