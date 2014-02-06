//
//  NCFittingTypeVariationsViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 06.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingTypeVariationsViewController.h"

@interface NCFittingTypeVariationsViewController ()

@end

@implementation NCFittingTypeVariationsViewController

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

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Unwind"]) {
		self.selectedType = [sender object];
	}
	else
		[super prepareForSegue:segue sender:sender];
}

@end
