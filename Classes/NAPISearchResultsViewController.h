//
//  NAPISearchResultsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 19.06.13.
//
//

#import <UIKit/UIKit.h>

@interface NAPISearchResultsViewController : UITableViewController
@property (nonatomic, strong) NSDictionary* criteria;
@property (weak, nonatomic) IBOutlet UISegmentedControl *orderSegmentedControl;
- (IBAction)onChangeOrder:(id)sender;

@end
