//
//  ModuleCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ModuleCellView : UITableViewCell
@property (nonatomic, retain) IBOutlet UIImageView *iconView;
@property (nonatomic, retain) IBOutlet UIImageView *stateView;
@property (nonatomic, retain) IBOutlet UIImageView *targetView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *row1Label;
@property (nonatomic, retain) IBOutlet UILabel *row2Label;
@property (nonatomic, retain) IBOutlet UILabel *row3Label;
@end
