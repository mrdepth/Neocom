//
//  DamagePatternCellView.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DamagePatternCellView.h"

@implementation DamagePatternCellView
@synthesize titleLabel;
@synthesize emLabel;
@synthesize kineticLabel;
@synthesize thermalLabel;
@synthesize explosiveLabel;
@synthesize checkmarkImageView;

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

- (void) dealloc {
	[titleLabel release];
	[emLabel release];
	[kineticLabel release];
	[thermalLabel release];
	[explosiveLabel release];
	[checkmarkImageView release];
	[super dealloc];
}

@end
