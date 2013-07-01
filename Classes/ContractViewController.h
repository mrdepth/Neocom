//
//  ContractViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEOnlineAPI.h"

@interface ContractViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView *contractTableView;
@property (nonatomic, weak) IBOutlet EVEContractsItem *contract;
@property (nonatomic) BOOL corporate;
@end