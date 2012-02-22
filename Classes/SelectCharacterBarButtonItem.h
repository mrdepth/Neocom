//
//  SelectCharacterBarButtonItem.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SelectCharacterBarButtonItem : UIBarButtonItem {
	UIViewController *parentViewController;
	UIViewController *modalViewController;
}
@property (nonatomic, assign) UIViewController *parentViewController;
@property (nonatomic, retain) UIViewController *modalViewController;

+ (id) barButtonItemWithParentViewController: (UIViewController*) controller;
- (id) initWithParentViewController: (UIViewController*) controller;

- (IBAction) onSelect: (id) sender;
- (IBAction) onBack: (id) sender;
- (void) setCharacterName:(NSString*) name;
@end
