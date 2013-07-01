//
//  AboutViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutViewController : UIViewController<UIAlertViewDelegate>
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIView *cacheView;
@property (nonatomic, strong) IBOutlet UIView *databaseView;
@property (nonatomic, strong) IBOutlet UIView *marketView;
@property (nonatomic, strong) IBOutlet UIView *versionView;
@property (nonatomic, strong) IBOutlet UIView *specialThanksView;
@property (nonatomic, strong) IBOutlet UILabel *apiCacheSizeLabel;
@property (nonatomic, strong) IBOutlet UILabel *imagesCacheSizeLabel;
@property (nonatomic, strong) IBOutlet UILabel *databaseVersionLabel;
@property (nonatomic, strong) IBOutlet UILabel *imagesVersionLabel;
@property (nonatomic, strong) IBOutlet UILabel *applicationVersionLabel;

- (IBAction) onClearCache:(id) sender;
- (IBAction) onHomepage:(id) sender;
- (IBAction) onMail:(id) sender;
- (IBAction) onSources:(id) sender;

@end