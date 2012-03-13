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

@class Fit;
@interface CharactersViewController : UIViewController<UITableViewDelegate, UITableViewDataSource> {
	UITableView *charactersTableView;
	id<CharactersViewControllerDelegate> delegate;
	Fit* modifiedFit;
@private
	NSMutableArray *sections;
}
@property (retain, nonatomic) IBOutlet UITableView *charactersTableView;
@property (nonatomic, assign) IBOutlet id<CharactersViewControllerDelegate> delegate;
@property (retain, nonatomic) Fit* modifiedFit;

- (IBAction) onClose:(id)sender;

@end
