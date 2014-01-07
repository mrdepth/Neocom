//
//  NCAccountsViewController.m
//  Neocom
//
//  Created by Admin on 04.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAccountsViewController.h"
#import "NCAccountsManager.h"

@interface NCAccountsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSMutableArray* accounts;
@property (nonatomic, strong) NSMutableArray* apiKeys;
@end

@implementation NCAccountsViewControllerData

@end


@interface NCAccountsViewController ()

@end

@implementation NCAccountsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCAccountsManager* accountsManager = [NCAccountsManager defaultManager];
											 NSError* error = nil;
											 [accountsManager reloadWithCachePolicy:cachePolicy error:&error];
											 
											 for (NCAccount* account in accountsManager.accounts) {
												 
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 
							 }];
}

@end
