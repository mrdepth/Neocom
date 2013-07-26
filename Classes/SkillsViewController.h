//
//  SkillsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CollapsableTableView.h"
#import "SkillsDataSource.h"
#import "SkillPlannerImportViewController.h"

@interface SkillsViewController : UIViewController<CollapsableTableViewDelegate, SkillPlannerImportViewControllerDelegate>
@property (nonatomic, weak) IBOutlet CollapsableTableView *skillsTableView;
@property (nonatomic, weak) IBOutlet CollapsableTableView *skillsQueueTableView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) IBOutlet SkillsDataSource *skillsDataSource;
@property (strong, nonatomic) IBOutlet SkillsDataSource *skillQueueDataSource;
@property (strong, nonatomic) IBOutlet UIButton *modeButton;

- (IBAction) onMode:(id)sender;
- (IBAction) onAction:(id)sender;

@end
