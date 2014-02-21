//
//  NCKillMailsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCKillMailsViewController.h"

@interface NCKillMailsViewControllerDataSection : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* kills;
@property (nonatomic, strong) NSString* title;
@end

@interface NCKillMailsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* sectionsKills;
@property (nonatomic, strong) NSArray* sectionsLosses;
@end

@interface NCKillMailsViewController ()

@end

@implementation NCKillMailsViewController

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
