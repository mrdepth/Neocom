//
//  NCSkillsDataSource.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NCSkillsViewController;
@interface NCSkillsDataSource : NSObject<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) NCSkillsViewController* skillsViewController;

- (void) reloadData;

@end
