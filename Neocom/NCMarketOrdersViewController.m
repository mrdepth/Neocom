//
//  NCMarketOrdersViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 17.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMarketOrdersViewController.h"
#import "EVEOnlineAPI.h"

@interface NCMarketOrdersViewControllerDataRow : NSObject<NSCoding>
@property (nonatomic, strong) EVEMarketOrdersItem* marketOrder;
@property (nonatomic, strong) NSString* stationID;
@end

@interface NCMarketOrdersViewControllerData: NSObject<NSCoding>

@end

@implementation NCMarketOrdersViewControllerDataRow


@end

@implementation NCMarketOrdersViewControllerData

@end

@interface NCMarketOrdersViewController ()

@end

@implementation NCMarketOrdersViewController

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
