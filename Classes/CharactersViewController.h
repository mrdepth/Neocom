//
//  CharactersViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Character.h"

@class ShipFit;
@interface CharactersViewController : UITableViewController
@property (nonatomic, copy) void (^completionHandler)(id<Character> character);

- (IBAction) onClose:(id)sender;

@end
