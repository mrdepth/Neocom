//
//  CertificateCellView.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificateCellView.h"

@implementation CertificateCellView
@synthesize iconView;
@synthesize stateView;
@synthesize titleLabel;
@synthesize detailLabel;

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
	[iconView release];
	[stateView release];
	[titleLabel release];
	[detailLabel release];
	[super dealloc];
}

@end
