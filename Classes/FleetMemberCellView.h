//
//  FleetMemberCellView.h
//  EVEUniverse
//
//  Created by mr_depth on 02.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FleetMemberCellView : UITableViewCell {
	UIImageView *iconView;
	UIImageView *stateView;
	UILabel *titleLabel;
	UILabel *fitNameLabel;
}
@property (nonatomic, retain) IBOutlet UIImageView *iconView;
@property (nonatomic, retain) IBOutlet UIImageView *stateView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *fitNameLabel;

@end
