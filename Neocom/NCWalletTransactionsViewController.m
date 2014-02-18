//
//  NCWalletTransactionsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 18.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCWalletTransactionsViewController.h"
#import "EVEOnlineAPI.h"
#import "NCLocationsManager.h"

@interface NCWalletTransactionsViewControllerDataRow : NSObject<NSCoding>
@property (nonatomic, strong) id transaction;
@property (nonatomic, strong) NCLocationsManagerItem* location;
@property (nonatomic, strong) EVEDBInvType* type;
@end

@interface NCWalletTransactionsViewControllerDataAccount : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* tansactions;
@property (nonatomic, strong) NSString* accountName;
@property (nonatomic, assign) float balance;
@end

@interface NCWalletTransactionsViewControllerData: NSObject<NSCoding>
@property (nonatomic, strong) NSArray* accounts;
@end

@interface NCWalletTransactionsViewController ()

@end

@implementation NCWalletTransactionsViewController

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

@end
