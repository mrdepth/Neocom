//
//  WalletTransactionCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WalletTransactionCellView.h"


@implementation WalletTransactionCellView

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


@end
