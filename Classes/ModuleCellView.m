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
@synthesize chargeLabel;
@synthesize rangeLabel;

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
	[chargeLabel release];
	[rangeLabel release];
    [super dealloc];
}


@end
