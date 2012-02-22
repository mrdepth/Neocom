//
//  FleetMemberCellView.m
//  EVEUniverse
//
//  Created by mr_depth on 02.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FleetMemberCellView.h"

@implementation FleetMemberCellView
@synthesize iconView;
@synthesize stateView;
@synthesize titleLabel;
@synthesize fitNameLabel;


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
	[iconView release];
	[stateView release];
	[titleLabel release];
	[fitNameLabel release];
    [super dealloc];
}


@end