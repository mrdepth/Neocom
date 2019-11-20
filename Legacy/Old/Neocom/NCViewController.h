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
@property (nonatomic, strong, readonly) NSManagedObjectContext* storageManagedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectContext* databaseManagedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectContext* cacheManagedObjectContext;
@property (nonatomic, strong, readonly) NCTaskManager* taskManager;

@end
