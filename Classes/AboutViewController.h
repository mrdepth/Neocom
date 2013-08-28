//
//  AboutViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutViewController : UITableViewController
@property (nonatomic, strong) IBOutlet UIButton* clearButton;
- (IBAction) onClearCache:(id) sender;

@end