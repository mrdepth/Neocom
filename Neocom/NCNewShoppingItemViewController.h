//
//  NCNewShoppingItemViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 28.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCNewShoppingItemViewController : NCTableViewController
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *quantityItem;
@property (nonatomic, strong) NSArray* items;
- (IBAction)onChangeQuantity:(id)sender;
- (IBAction)onSetQuantity:(id)sender;
- (IBAction)onAdd:(id)sender;
@end
