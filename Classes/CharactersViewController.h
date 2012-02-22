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

@interface CharactersViewController : UIViewController<UITableViewDelegate, UITableViewDataSource> {
	UITableView *charactersTableView;
	id<CharactersViewControllerDelegate> delegate;
@private
	NSMutableArray *sections;
}
@property (retain, nonatomic) IBOutlet UITableView *charactersTableView;
@property (nonatomic, assign) IBOutlet id<CharactersViewControllerDelegate> delegate;

- (IBAction) onClose:(id)sender;

@end
