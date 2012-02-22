//
//  POSFuelCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "POSFuelCellView.h"


@implementation POSFuelCellView
@synthesize typeNameLabel;
@synthesize remainsLabel;
@synthesize consumptionLabel;
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
	[typeNameLabel release];
	[remainsLabel release];
	[consumptionLabel release];
	[iconImageView release];
    [super dealloc];
}


@end
