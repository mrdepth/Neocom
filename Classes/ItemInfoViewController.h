//
//  ItemInfoViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEDBAPI.h"

@interface ItemInfoViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (nonatomic, retain) IBOutlet UITableView *attributesTable;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *volumeLabel;
@property (nonatomic, retain) IBOutlet UILabel *massLabel;
@property (nonatomic, retain) IBOutlet UILabel *capacityLabel;
@property (nonatomic, retain) IBOutlet UILabel *radiusLabel;
@property (nonatomic, retain) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIImageView *techLevelImageView;
@property (nonatomic, retain) IBOutlet UIView *typeInfoView;
@property (nonatomic, assign) IBOutlet UIViewController *containerViewController;
@property (nonatomic, retain) EVEDBInvType *type;

@end
