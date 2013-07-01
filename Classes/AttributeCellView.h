//
//  AttributeCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AttributeCellView : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *iconView;
@property (nonatomic, weak) IBOutlet UILabel *attributeNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *attributeValueLabel;

@end
