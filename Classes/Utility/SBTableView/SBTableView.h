//
//  SBTableView.h
//  AutoHidingBar
//
//  Created by Shimanski on 11/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SBTableView : UITableView<UITableViewDelegate> {
	UIView *topView;
	id <UITableViewDelegate> delegate;
	float visibleTopPartHeight;
}
@property (nonatomic, retain) IBOutlet UIView *topView;
@property (nonatomic, assign) id <UITableViewDelegate> delegate;
@property (nonatomic, assign) float visibleTopPartHeight;

@end
