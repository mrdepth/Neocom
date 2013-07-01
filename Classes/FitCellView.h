//
//  FitCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FitCellView : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *iconView;
@property (nonatomic, weak) IBOutlet UILabel *shipNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *fitNameLabel;

@end
