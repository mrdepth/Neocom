//
//  SkillLevelsViewController.h
//  EVEUniverse
//
//  Created by mr_depth on 28.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SkillLevelsViewControllerDelegate.h"

@interface SkillLevelsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (retain, nonatomic) IBOutlet UITableView *skillLevelsTableView;
@property (assign, nonatomic) IBOutlet id<SkillLevelsViewControllerDelegate> delegate;
@property (assign, nonatomic) NSInteger currentLevel;

@end
