//
//  KillMailViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 09.11.12.
//
//

#import <UIKit/UIKit.h>
#import "KillMail.h"
#import "CollapsableTableView.h"

@interface KillMailViewController : UITableViewController<CollapsableTableViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *allianceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *corporationNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *characterImageView;
@property (weak, nonatomic) IBOutlet UIImageView *allianceImageView;
@property (weak, nonatomic) IBOutlet UIImageView *corporationImageView;
@property (weak, nonatomic) IBOutlet UILabel *killTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *shipNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *shipImageView;
@property (weak, nonatomic) IBOutlet UILabel *solarSystemNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *securityStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *regionNameLabel;
@property (strong, nonatomic) IBOutlet UISegmentedControl *sectionSegmentedControler;
@property (weak, nonatomic) IBOutlet UILabel *damageTakenLabel;
@property (strong, nonatomic) KillMail* killMail;

- (IBAction)onChangeSection:(id)sender;

@end
