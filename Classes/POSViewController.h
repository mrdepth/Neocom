//
//  POSViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EVEDBInvType;
@class EVEDBMapSolarSystem;
@interface POSViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, retain) IBOutlet UITableView *posTableView;
@property (nonatomic, retain) EVEDBInvType *controlTowerType;
@property (nonatomic, retain) EVEDBMapSolarSystem *solarSystem;
@property (nonatomic, retain) NSString *location;
@property (nonatomic) long long posID;
@property (nonatomic) float sovereigntyBonus;
@end
