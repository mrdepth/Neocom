//
//  ItemCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ItemCellView : UITableViewCell {
	UIImageView *iconImageView;
	UILabel *titleLabel;
}
@property (nonatomic, retain) IBOutlet UIImageView *iconImageView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;

@end
