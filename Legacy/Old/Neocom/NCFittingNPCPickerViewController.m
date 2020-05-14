//
//  NCFittingNPCPickerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 05.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingNPCPickerViewController.h"
#import "NCTableViewCell.h"

@interface NCFittingNPCPickerViewController ()

@end

@implementation NCFittingNPCPickerViewController

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
		if ([sender isKindOfClass:[NCTableViewCell class]])
			self.selectedNPCType = [sender object];
	}
	else
		[super prepareForSegue:segue sender:sender];
}

@end
