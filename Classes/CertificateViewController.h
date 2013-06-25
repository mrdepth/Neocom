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
@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet CertificateTreeView *certificateTreeView;
@property (retain, nonatomic) IBOutlet UITableView *recommendationsTableView;
@property (retain, nonatomic) IBOutlet UIView *contentView;
@property (retain, nonatomic) IBOutlet UISegmentedControl *pageSegmentControl;
@property (retain, nonatomic) EVEDBCrtCertificate* certificate;

- (IBAction) dismissModalViewController:(id) sender;
- (IBAction) onSwitchScreens:(id)sender;

@end
