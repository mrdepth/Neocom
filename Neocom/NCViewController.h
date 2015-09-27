//
//  NCViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 26.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCTaskManager.h"

@interface NCViewController : UIViewController
@property (nonatomic, strong) NSManagedObjectContext* storageManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext* databaseManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext* cacheManagedObjectContext;
@property (nonatomic, strong, readonly) NCTaskManager* taskManager;

@end
