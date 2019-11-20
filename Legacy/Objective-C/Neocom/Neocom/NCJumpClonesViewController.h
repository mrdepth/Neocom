//
//  NCJumpClonesViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASTreeController.h"

@interface NCJumpClonesViewController : UITableViewController<ASTreeControllerDelegate>
@property (strong, nonatomic) IBOutlet ASTreeController *treeController;

@end
