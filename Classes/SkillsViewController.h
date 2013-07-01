//
//  SkillsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CharacterInfoViewController.h"
#import "CollapsableTableView.h"

@interface SkillsViewController : UIViewController<UITableViewDataSource, CollapsableTableViewDelegate>
@property (nonatomic, weak) IBOutlet CollapsableTableView *skillsTableView;
@property (nonatomic, weak) IBOutlet CollapsableTableView *skillsQueueTableView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) IBOutlet CharacterInfoViewController *characterInfoViewController;

- (IBAction) onChangeSegmentedControl:(id) sender;

@end
