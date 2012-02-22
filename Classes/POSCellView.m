//
//  POSCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "POSCellView.h"


@implementation POSCellView
@synthesize typeNameLabel;
@synthesize locationLabel;
@synthesize stateLabel;
@synthesize fuelRemainsLabel;
@synthesize iconImageView;
@synthesize fuelImageView;

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
	[locationLabel release];
	[stateLabel release];
	[fuelRemainsLabel release];
	[iconImageView release];
	[fuelImageView release];
    [super dealloc];
}


@end
