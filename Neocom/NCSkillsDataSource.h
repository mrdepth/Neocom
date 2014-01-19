//
//  NCSkillsDataSource.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCStorage.h"

@class NCSkillsViewController;
@interface NCSkillsDataSource : NSObject<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) NSArray* sections;
@property (weak, nonatomic) NCSkillsViewController* skillsViewController;

- (void) reloadData;

@end
