//
//  NCZKillBoardViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 26.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCZKillBoardViewController.h"

@interface NCZKillBoardViewController ()
@property (nonatomic, strong) EVEDBInvGroup* group;
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, strong) EVEDBMapSolarSystem* solarSystem;
@property (nonatomic, strong) EVEDBMapRegion* region;
@property (nonatomic, strong) EVECharacterIDItem* character;
@property (nonatomic, strong) EVECharacterIDItem* corporation;
@property (nonatomic, strong) EVECharacterIDItem* alliance;
@end

@implementation NCZKillBoardViewController

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
