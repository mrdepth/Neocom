//
//  SkillLevelsViewController.h
//  EVEUniverse
//
//  Created by mr_depth on 28.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SkillLevelsViewController : UITableViewController
@property (assign, nonatomic) NSInteger currentLevel;
@property (nonatomic, copy) void (^completionHandler)(NSInteger level);

@end
