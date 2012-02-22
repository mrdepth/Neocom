//
//  ContractInfoCellView.m
//  EVEUniverse
//
//  Created by Mr. Depth on 9/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ContractInfoCellView.h"


@implementation ContractInfoCellView
@synthesize titleLabel;
@synthesize valueLabel;

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
	[titleLabel release];
	[valueLabel release];
    [super dealloc];
}


@end
