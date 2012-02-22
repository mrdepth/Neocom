//
//  MainMenuCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MainMenuCellView : UITableViewCell {
	UILabel *titleLabel;
	UIImageView *iconImageView;
}
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UIImageView *iconImageView;

@end
