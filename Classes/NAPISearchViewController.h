//
//  NAPISearchViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 18.06.13.
//
//

#import <UIKit/UIKit.h>
#import "NCItemsViewController.h"
#import "KillNetFilterShipClassesViewController.h"

@interface NAPISearchViewController : UITableViewController<KillNetFilterDBViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *fitsCountLabel;

- (IBAction)onClose:(id)sender;
- (IBAction)onSearch:(id)sender;
@end
