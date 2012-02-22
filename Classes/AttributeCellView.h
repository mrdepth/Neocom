//
//  AttributeCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AttributeCellView : UITableViewCell {
	UIImageView *iconView;
	UILabel *attributeNameLabel;
	UILabel *attributeValueLabel;
}
@property (nonatomic, retain) IBOutlet UIImageView *iconView;
@property (nonatomic, retain) IBOutlet UILabel *attributeNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *attributeValueLabel;

@end
