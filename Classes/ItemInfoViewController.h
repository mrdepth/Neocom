//
//  ItemInfoViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEDBAPI.h"

@interface ItemInfoViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *volumeLabel;
@property (nonatomic, weak) IBOutlet UILabel *massLabel;
@property (nonatomic, weak) IBOutlet UILabel *capacityLabel;
@property (nonatomic, weak) IBOutlet UILabel *radiusLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIImageView *techLevelImageView;
@property (nonatomic, weak) IBOutlet UIView *typeInfoView;
@property (nonatomic, weak) IBOutlet UIViewController *containerViewController;
@property (nonatomic, strong) EVEDBInvType *type;

@end
