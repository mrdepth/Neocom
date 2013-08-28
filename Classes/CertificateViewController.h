//
//  CertificateViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CertificateTreeView.h"

@class EVEDBCrtCertificate;
@interface CertificateViewController : UIViewController<UIScrollViewDelegate, CertificateTreeViewDelegate, UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet CertificateTreeView *certificateTreeView;
@property (strong, nonatomic) IBOutlet UITableView *recommendationsTableView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *pageSegmentControl;
@property (strong, nonatomic) EVEDBCrtCertificate* certificate;

- (IBAction) onSwitchScreens:(id)sender;

@end
