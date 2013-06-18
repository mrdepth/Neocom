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

@interface SkillsViewController : UIViewController<UITableViewDataSource, CollapsableTableViewDelegate> {
	CollapsableTableView *skillsTableView;
	CollapsableTableView *skillsQueueTableView;
	UISegmentedControl *segmentedControl;
	CharacterInfoViewController *characterInfoViewController;
@private
}
@property (nonatomic, retain) IBOutlet CollapsableTableView *skillsTableView;
@property (nonatomic, retain) IBOutlet CollapsableTableView *skillsQueueTableView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, retain) IBOutlet CharacterInfoViewController *characterInfoViewController;

- (IBAction) onChangeSegmentedControl:(id) sender;

@end
