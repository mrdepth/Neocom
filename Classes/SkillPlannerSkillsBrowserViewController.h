//
//  SkillPlannerSkillsBrowserViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 20.06.13.
//
//

#import <UIKit/UIKit.h>

@interface SkillPlannerSkillsBrowserViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UISegmentedControl *filterSegmentedControl;
- (IBAction)onChangeFilter:(id)sender;
- (IBAction)onClose:(id)sender;
@end
