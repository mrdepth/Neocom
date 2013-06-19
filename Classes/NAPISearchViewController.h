//
//  NAPISearchViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 18.06.13.
//
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewController.h"
#import "KillNetFilterShipClassesViewController.h"
#import "NAPISearchTitleCellView.h"
#import "NAPISearchSwitchCellView.h"

@interface NAPISearchViewController : UIViewController<FittingItemsViewControllerDelegate, KillNetFilterDBViewControllerDelegate, NAPISearchTitleCellViewDelegate, NAPISearchSwitchCellViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (nonatomic, strong) IBOutlet UINavigationController *fittingItemsNavigationController;
@property (weak, nonatomic) IBOutlet KillNetFilterShipClassesViewController *shipClassesViewController;
@property (strong, nonatomic) IBOutlet UINavigationController *shipClassesNavigationController;
@property (weak, nonatomic) IBOutlet UILabel *fitsCountLabel;

- (IBAction)onClose:(id)sender;
- (IBAction)onSearch:(id)sender;
@end
