//
//  NibTableViewCell.h
//  
//
//  Created by Shimanski on 12/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UITableViewCell(NibTableViewCell)
+ (id) cellWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle reuseIdentifier:(NSString *)reuseIdentifier;
@end
