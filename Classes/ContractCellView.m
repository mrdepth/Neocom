//
//  ContractCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ContractCellView.h"


@implementation ContractCellView
@synthesize statusLabel;
@synthesize typeLabel;
@synthesize titleLabel;
@synthesize locationLabel;
@synthesize startTimeLabel;
@synthesize characterLabel;
@synthesize priceLabel;
@synthesize priceTitleLabel;
@synthesize buyoutLabel;


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
	[statusLabel release];
	[typeLabel release];
	[titleLabel release];
	[locationLabel release];
	[startTimeLabel release];
	[characterLabel release];
	[priceLabel release];
	[priceTitleLabel release];
	[buyoutLabel release];
    [super dealloc];
}


@end
