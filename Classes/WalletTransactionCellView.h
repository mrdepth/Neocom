//
//  WalletTransactionCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupedCell.h"


@interface WalletTransactionCellView : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *transactionAmmountLabel;
@property (nonatomic, weak) IBOutlet UILabel *typeNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *priceLabel;
@property (nonatomic, weak) IBOutlet UILabel *characterLabel;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;

@end
