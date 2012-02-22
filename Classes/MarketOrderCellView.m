//
//  MarketOrderCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MarketOrderCellView.h"


@implementation MarketOrderCellView
@synthesize expireInLabel;
@synthesize stateLabel;
@synthesize typeNameLabel;
@synthesize locationLabel;
@synthesize priceLabel;
@synthesize qtyLabel;
@synthesize issuedLabel;
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
	[expireInLabel release];
	[stateLabel release];
	[typeNameLabel release];
	[locationLabel release];
	[priceLabel release];
	[qtyLabel release];
	[issuedLabel release];
	[characterLabel release];
	[iconImageView release];
    [super dealloc];
}


@end
