//
//  KillboardApiViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 02.11.12.
//
//

#import <UIKit/UIKit.h>
#import "FilterViewController.h"

@interface KillboardApiViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UISegmentedControl *ownerSegmentControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *killboardTypeSegmentControl;
@property (strong, nonatomic) IBOutlet UINavigationController *filterNavigationViewController;
@property (weak, nonatomic) IBOutlet FilterViewController *filterViewController;

- (IBAction) onChangeOwner:(id) sender;
- (IBAction) onChangeKillboardType:(id) sender;

@end
