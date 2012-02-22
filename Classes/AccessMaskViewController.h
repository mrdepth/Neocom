//
//  AccessMaskViewController.h
//  EVEUniverse
//
//  Created by Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEOnlineAPI.h"

@interface AccessMaskViewController : UIViewController<UITableViewDataSource, UITableViewDelegate> {
	UITableView *accessMaskTableView;
	NSInteger accessMask;
	BOOL corporate;
@private
	NSArray *sections;
	NSDictionary *groups;
}
@property (nonatomic, retain) IBOutlet UITableView *accessMaskTableView;
@property (nonatomic, assign) NSInteger accessMask;
@property (nonatomic, assign, getter=isCorporate) BOOL corporate;

@end
