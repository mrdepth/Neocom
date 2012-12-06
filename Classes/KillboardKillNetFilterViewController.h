//
//  KillboardKillNetFilterViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import <UIKit/UIKit.h>
#import "KillNetFiltersViewController.h"
#import "KillNetFilterValueCellView.h"
#import "KillNetFilterTextCellView.h"
#import "FittingItemsViewController.h"
#import "KillNetFilterDBViewController.h"
#import "KillNetFilterDateViewController.h"

@interface KillboardKillNetFilterViewController : UITableViewController<KillNetFiltersViewControllerDelegate, KillNetFilterTextCellViewDelegate, FittingItemsViewControllerDelegate, KillNetFilterDBViewControllerDelegate, KillNetFilterDateViewControllerDelegate, UITextFieldDelegate>
@property (retain, nonatomic) IBOutlet UIView *sectionFooterView;
@property (retain, nonatomic) IBOutlet UILabel *searchResultsCountLabel;

@end
