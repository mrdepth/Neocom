//
//  ModuleCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ModuleCellView : UITableViewCell {
	UIImageView *iconView;
	UIImageView *stateView;
	UIImageView *targetView;
	UILabel *titleLabel;
	UILabel *chargeLabel;
	UILabel *rangeLabel;
}
@property (nonatomic, retain) IBOutlet UIImageView *iconView;
@property (nonatomic, retain) IBOutlet UIImageView *stateView;
@property (nonatomic, retain) IBOutlet UIImageView *targetView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *chargeLabel;
@property (nonatomic, retain) IBOutlet UILabel *rangeLabel;
@end
