//
//  SBTableView.h
//  AutoHidingBar
//
//  Created by Shimanski on 11/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SBTableView : UITableView<UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UIView *topView;
@property (nonatomic, weak) id <UITableViewDelegate> delegate;
@property (nonatomic, assign) float visibleTopPartHeight;

@end
