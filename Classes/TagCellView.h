//
//  TagCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TagCellView : UITableViewCell {
	UILabel *titleLabel;
	UIImageView *checkmarkImageView;
}
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UIImageView *checkmarkImageView;

@end
