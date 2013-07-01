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
@property (nonatomic, weak) IBOutlet UITableView *posTableView;
@property (nonatomic, strong) EVEDBInvType *controlTowerType;
@property (nonatomic, strong) EVEDBMapSolarSystem *solarSystem;
@property (nonatomic, strong) NSString *location;
@property (nonatomic) long long posID;
@property (nonatomic) float sovereigntyBonus;
@end
