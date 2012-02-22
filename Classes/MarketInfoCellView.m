//
//  MarketInfoCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MarketInfoCellView.h"


@implementation MarketInfoCellView
@synthesize systemLabel;
@synthesize stationLabel;
@synthesize securityLabel;
@synthesize priceLabel;
@synthesize qtyLabel;
@synthesize reportedLabel;

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
	[systemLabel release];
	[stationLabel release];
	[securityLabel release];
	[priceLabel release];
	[qtyLabel release];
	[reportedLabel release];
    [super dealloc];
}


@end
