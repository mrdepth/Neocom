//
//  WalletJournalCellView.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WalletJournalCellView.h"

@implementation WalletJournalCellView
@synthesize dateLabel;
@synthesize amountLabel;
@synthesize titleLabel;
@synthesize nameLabel;
@synthesize balanceLabel;
@synthesize taxLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
	[dateLabel release];
	[amountLabel release];
	[titleLabel release];
	[nameLabel release];
	[balanceLabel release];
	[taxLabel release];
	[super dealloc];
}
@end
