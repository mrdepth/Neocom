//
//  NCDatabaseTypesViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCDatabaseTypesViewController : UITableViewController
@property (nonatomic, strong) NSPredicate* predicate;
- (void) reloadData;
@end
