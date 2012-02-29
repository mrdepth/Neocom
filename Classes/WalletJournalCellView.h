//
//  WalletJournalCellView.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WalletJournalCellView : UITableViewCell {
	UILabel *dateLabel;
	UILabel *amountLabel;
	UILabel *titleLabel;
	UILabel *nameLabel;
	UILabel *balanceLabel;
	UILabel *taxLabel;
}

@property (retain, nonatomic) IBOutlet UILabel *dateLabel;
@property (retain, nonatomic) IBOutlet UILabel *amountLabel;
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *nameLabel;
@property (retain, nonatomic) IBOutlet UILabel *balanceLabel;
@property (retain, nonatomic) IBOutlet UILabel *taxLabel;

@end
