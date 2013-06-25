//
//  FitCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FitCellView : UITableViewCell
@property (nonatomic, retain) IBOutlet UIImageView *iconView;
@property (nonatomic, retain) IBOutlet UILabel *shipNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *fitNameLabel;

@end
