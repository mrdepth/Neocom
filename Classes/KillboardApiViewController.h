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
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ownerSegmentControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *killboardTypeSegmentControl;
@property (strong, nonatomic) IBOutlet UINavigationController *filterNavigationViewController;
@property (weak, nonatomic) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, strong) UIPopoverController *filterPopoverController;

- (IBAction) onChangeOwner:(id) sender;
- (IBAction) onChangeKillboardType:(id) sender;

@end
