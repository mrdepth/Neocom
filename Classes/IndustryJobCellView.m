//
//  IndustryJobCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IndustryJobCellView.h"


@implementation IndustryJobCellView
@synthesize remainsLabel;
@synthesize activityLabel;
@synthesize typeNameLabel;
@synthesize locationLabel;
@synthesize startTimeLabel;
@synthesize characterLabel;
@synthesize iconImageView;
@synthesize activityImageView;

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
	[remainsLabel release];
	[activityLabel release];
	[typeNameLabel release];
	[locationLabel release];
	[startTimeLabel release];
	[characterLabel release];
	[iconImageView release];
	[activityImageView release];
    [super dealloc];
}


@end
