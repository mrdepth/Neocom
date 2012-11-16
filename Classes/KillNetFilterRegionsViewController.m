//
//  KillNetFilterRegionsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 16.11.12.
//
//

#import "KillNetFilterRegionsViewController.h"

@interface KillNetFilterRegionsViewController ()

@end

@implementation KillNetFilterRegionsViewController

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
	self.groupsRequest = nil;
	self.itemsRequest = @"SELECT regionName as name, regionID as itemID FROM mapRegions as a WHERE 1 %@ ORDER BY regionName";
	self.searchRequest = @"regionName LIKE \"%%%@%%\"";
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
