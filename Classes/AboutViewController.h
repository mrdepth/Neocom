//
//  AboutViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutViewController : UIViewController<UIAlertViewDelegate, SKPaymentTransactionObserver> {
	UIScrollView *scrollView;
	UIView *cacheView;
	UIView *upgradeView;
	UIView *donateView;
	UIView *databaseView;
	UIView *marketView;
	UIView *versionView;
	UIView *specialThanksView;
	UILabel *apiCacheSizeLabel;
	UILabel *imagesCacheSizeLabel;
	UILabel *databaseVersionLabel;
	UILabel *imagesVersionLabel;
	UILabel *applicationVersionLabel;
}
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIView *cacheView;
@property (nonatomic, retain) IBOutlet UIView *upgradeView;
@property (nonatomic, retain) IBOutlet UIView *donateView;
@property (nonatomic, retain) IBOutlet UIView *databaseView;
@property (nonatomic, retain) IBOutlet UIView *marketView;
@property (nonatomic, retain) IBOutlet UIView *versionView;
@property (nonatomic, retain) IBOutlet UIView *specialThanksView;
@property (nonatomic, retain) IBOutlet UILabel *apiCacheSizeLabel;
@property (nonatomic, retain) IBOutlet UILabel *imagesCacheSizeLabel;
@property (nonatomic, retain) IBOutlet UILabel *databaseVersionLabel;
@property (nonatomic, retain) IBOutlet UILabel *imagesVersionLabel;
@property (nonatomic, retain) IBOutlet UILabel *applicationVersionLabel;

- (IBAction) onClearCache:(id) sender;
- (IBAction) onUpgrade:(id) sender;
- (IBAction) onDonate:(id) sender;
- (IBAction) onHomepage:(id) sender;
- (IBAction) onMail:(id) sender;

@end