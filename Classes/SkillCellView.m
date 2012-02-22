//
//  SkillCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SkillCellView.h"


@implementation SkillCellView
@synthesize iconImageView;
@synthesize levelImageView;
@synthesize skillLabel;
@synthesize skillPointsLabel;
@synthesize levelLabel;
@synthesize remainingLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
	if (![levelImageView isAnimating])
		[levelImageView startAnimating];
    
    // Configure the view for the selected state.
}


- (void)dealloc {
	[iconImageView release];
	[levelImageView release];
	[skillLabel release];
	[skillPointsLabel release];
	[levelLabel release];
	[remainingLabel release];
    [super dealloc];
}


@end
