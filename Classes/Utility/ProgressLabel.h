//
//  ProgressLabel.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ProgressLabel : UILabel
@property (nonatomic, assign) float progress;
@property (nonatomic, retain) UIColor *color;
@end
