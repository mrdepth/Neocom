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

@interface KillMailViewController : UIViewController<UITableViewDataSource, CollapsableTableViewDelegate>
@property (retain, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *allianceNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *corporationNameLabel;
@property (retain, nonatomic) IBOutlet UIImageView *characterImageView;
@property (retain, nonatomic) IBOutlet UIImageView *allianceImageView;
@property (retain, nonatomic) IBOutlet UIImageView *corporationImageView;
@property (retain, nonatomic) IBOutlet UILabel *killTimeLabel;
@property (retain, nonatomic) IBOutlet UILabel *shipNameLabel;
@property (retain, nonatomic) IBOutlet UIImageView *shipImageView;
@property (retain, nonatomic) IBOutlet UILabel *solarSystemNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *securityStatusLabel;
@property (retain, nonatomic) IBOutlet UILabel *regionNameLabel;
@property (retain, nonatomic) IBOutlet UISegmentedControl *sectionSegmentedControler;
@property (retain, nonatomic) IBOutlet CollapsableTableView *tableView;
@property (retain, nonatomic) IBOutlet UILabel *damageTakenLabel;
@property (retain, nonatomic) KillMail* killMail;

- (IBAction)onChangeSection:(id)sender;

@end
