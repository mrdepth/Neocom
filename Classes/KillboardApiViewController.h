//
//  KillboardApiViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 02.11.12.
//
//

#import <UIKit/UIKit.h>
#import "FilterViewController.h"

@interface KillboardApiViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UISegmentedControl *ownerSegmentControl;
@property (retain, nonatomic) IBOutlet UISegmentedControl *killboardTypeSegmentControl;
@property (retain, nonatomic) IBOutlet UINavigationController *filterNavigationViewController;
@property (retain, nonatomic) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, retain) UIPopoverController *filterPopoverController;

- (IBAction) onChangeOwner:(id) sender;
- (IBAction) onChangeKillboardType:(id) sender;

@end
