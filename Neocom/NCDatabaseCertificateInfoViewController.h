//
//  NCDatabaseCertificateInfoViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 23.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "EVEDBAPI.h"

typedef NS_ENUM(NSInteger, NCDatabaseCertificateInfoViewControllerMode) {
	NCDatabaseCertificateInfoViewControllerModeMasteries,
	NCDatabaseCertificateInfoViewControllerModeRequiredFor
};

@interface NCDatabaseCertificateInfoViewController : NCTableViewController
@property (strong, nonatomic) EVEDBCertCertificate* certificate;
@property (weak, nonatomic) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet UILabel* titleLabel;
@property (weak, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (assign, nonatomic) NCDatabaseCertificateInfoViewControllerMode mode;

- (IBAction)onChangeMode:(id)sender;

@end
