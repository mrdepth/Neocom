//
//  LoadoutCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LoadoutCellView.h"


@implementation LoadoutCellView
@synthesize iconImageView;
@synthesize titleLabel;
@synthesize thumbsUpLabel;
@synthesize thumbsDownLabel;

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
	[iconImageView release];
	[titleLabel release];
	[thumbsUpLabel release];
	[thumbsDownLabel release];
    [super dealloc];
}


@end
