//
//  WalletTransactionCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WalletTransactionCellView.h"


@implementation WalletTransactionCellView
@synthesize dateLabel;
@synthesize transactionAmmountLabel;
@synthesize typeNameLabel;
@synthesize locationLabel;
@synthesize priceLabel;
@synthesize characterLabel;
@synthesize iconImageView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state.
}


- (void)dealloc {
	[dateLabel release];
	[transactionAmmountLabel release];
	[typeNameLabel release];
	[locationLabel release];
	[priceLabel release];
	[characterLabel release];
	[iconImageView release];
	
    [super dealloc];
}


@end
