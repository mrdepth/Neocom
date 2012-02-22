//
//  ItemInfoViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEDBAPI.h"

@interface ItemInfoViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate> {
	UITableView *attributesTable;
	UILabel *titleLabel;
	UILabel *volumeLabel;
	UILabel *massLabel;
	UILabel *capacityLabel;
	UILabel *radiusLabel;
	UILabel *descriptionLabel;
	UIImageView *imageView;
	UIImageView *techLevelImageView;
	UIView *typeInfoView;
	UIViewController *containerViewController;
	EVEDBInvType *type;
	NSMutableArray *sections;
@private
	NSTimeInterval trainingTime;
	NSIndexPath* modifiedIndexPath;
}
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
