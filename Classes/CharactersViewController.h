//
//  CharactersViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CharactersViewControllerDelegate.h"
#import "Character.h"

@class ShipFit;
@interface CharactersViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *charactersTableView;
@property (nonatomic, weak) IBOutlet id<CharactersViewControllerDelegate> delegate;
@property (strong, nonatomic) ShipFit* modifiedFit;

- (IBAction) onClose:(id)sender;

@end
