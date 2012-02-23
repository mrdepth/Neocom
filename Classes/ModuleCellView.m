//
//  ModuleCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ModuleCellView.h"


@implementation ModuleCellView
@synthesize iconView;
@synthesize stateView;
@synthesize targetView;
@synthesize titleLabel;
@synthesize row1Label;
@synthesize row2Label;
@synthesize row3Label;

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
	[targetView release];
	[titleLabel release];
	[row1Label release];
	[row2Label release];
	[row3Label release];
    [super dealloc];
}


@end
