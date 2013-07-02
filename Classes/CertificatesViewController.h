//
//  CertificatesViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EVEDBCrtCategory;
@interface CertificatesViewController : UITableViewController
@property (nonatomic, strong) EVEDBCrtCategory* category;

@end
