//
//  ContractCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ContractCellView : UITableViewCell {
	UILabel *statusLabel;
	UILabel *typeLabel;
	UILabel *titleLabel;
	UILabel *locationLabel;
	UILabel *startTimeLabel;
	UILabel *characterLabel;
	UILabel *priceLabel;
	UILabel *priceTitleLabel;
	UILabel *buyoutLabel;
}
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UILabel *typeLabel;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *locationLabel;
@property (nonatomic, retain) IBOutlet UILabel *startTimeLabel;
@property (nonatomic, retain) IBOutlet UILabel *characterLabel;
@property (nonatomic, retain) IBOutlet UILabel *priceLabel;
@property (nonatomic, retain) IBOutlet UILabel *priceTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *buyoutLabel;

@end
