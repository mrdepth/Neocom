//
//  SkillEditingCellView.m
//  EVEUniverse
//
//  Created by mr_depth on 27.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SkillEditingCellView.h"

@implementation SkillEditingCellView
@synthesize iconImageView;
@synthesize levelImageView;
@synthesize skillLabel;

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
	[iconImageView release];
	[levelImageView release];
	[skillLabel release];
	[super dealloc];
}
@end
