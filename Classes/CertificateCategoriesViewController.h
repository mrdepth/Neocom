//
//  CertificateCategoriesViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CertificateCategoriesViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, retain) IBOutlet UITableView* categoriesTableView;

@end
