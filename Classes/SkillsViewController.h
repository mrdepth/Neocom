//
//  SkillsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CharacterInfoViewController.h"
#import "SBTableView.h"

@interface SkillsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, CharacterInfoViewControllerDelegate> {
	SBTableView *skillsTableView;
	SBTableView *skillsQueueTableView;
	UISegmentedControl *segmentedControl;
	CharacterInfoViewController *characterInfoViewController;
	UIView *characterInfoView;
@private
	NSArray *skillGroups;
	NSMutableArray *skillQueue;
	NSString *skillQueueTitle;
}
@property (nonatomic, retain) IBOutlet SBTableView *skillsTableView;
@property (nonatomic, retain) IBOutlet SBTableView *skillsQueueTableView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, retain) IBOutlet CharacterInfoViewController *characterInfoViewController;
@property (nonatomic, retain) IBOutlet UIView *characterInfoView;

- (IBAction) onChangeSegmentedControl:(id) sender;

@end
