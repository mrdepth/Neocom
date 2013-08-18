//
//  KillboardKillNetFilterViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import <UIKit/UIKit.h>
#import "KillNetFiltersViewController.h"
#import "KillNetFilterTextCellView.h"
#import "KillNetFilterDBViewController.h"
#import "KillNetFilterDateViewController.h"

@interface KillboardKillNetFilterViewController : UITableViewController<KillNetFiltersViewControllerDelegate, KillNetFilterTextCellViewDelegate, KillNetFilterDBViewControllerDelegate, KillNetFilterDateViewControllerDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *searchResultsCountLabel;

@end
