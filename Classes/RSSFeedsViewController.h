//
//  RSSFeedsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RSSFeedsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource> {
@private
	NSArray *sections;
}

@end
