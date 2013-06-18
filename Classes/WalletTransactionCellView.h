//
//  WalletTransactionCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WalletTransactionCellView : UITableViewCell
@property (nonatomic, retain) IBOutlet UILabel *dateLabel;
@property (nonatomic, retain) IBOutlet UILabel *transactionAmmountLabel;
@property (nonatomic, retain) IBOutlet UILabel *typeNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *locationLabel;
@property (nonatomic, retain) IBOutlet UILabel *priceLabel;
@property (nonatomic, retain) IBOutlet UILabel *characterLabel;
@property (nonatomic, retain) IBOutlet UIImageView *iconImageView;

@end
