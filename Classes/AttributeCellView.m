//
//  AttributeCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AttributeCellView.h"


@implementation AttributeCellView
@synthesize iconView;
@synthesize attributeNameLabel;
@synthesize attributeValueLabel;

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
	[attributeNameLabel release];
	[attributeValueLabel release];
	
    [super dealloc];
}


@end
