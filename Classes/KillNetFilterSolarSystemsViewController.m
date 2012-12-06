//
//  KillNetFilterSolarSystemsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 16.11.12.
//
//

#import "KillNetFilterSolarSystemsViewController.h"

@interface KillNetFilterSolarSystemsViewController ()

@end

@implementation KillNetFilterSolarSystemsViewController

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
	self.groupsRequest = @"SELECT regionName as name, regionID as itemID FROM mapRegions as a ORDER BY regionName";
	self.itemsRequest = @"SELECT solarSystemName as name, solarSystemID as itemID, regionName as groupName FROM mapSolarSystems as a, mapRegions as b WHERE a.regionID=b.regionID %@ ORDER BY solarSystemName";
	self.searchRequest = @"solarSystemName LIKE \"%%%@%%\"";
	self.groupName = @"a.regionID";
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
