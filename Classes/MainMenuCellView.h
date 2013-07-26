//
//  MainMenuCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupedCell.h"

@interface MainMenuCellView : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;

@end
