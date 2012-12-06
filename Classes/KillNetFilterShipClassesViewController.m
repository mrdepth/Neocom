//
//  KillNetFilterShipClassesViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 16.11.12.
//
//

#import "KillNetFilterShipClassesViewController.h"

@interface KillNetFilterShipClassesViewController ()

@end

@implementation KillNetFilterShipClassesViewController

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
	self.itemsRequest = @"SELECT groupName as name, groupID as itemID FROM invGroups WHERE categoryID=6 %@ ORDER BY groupName";
	self.searchRequest = @"groupName LIKE \"%%%@%%\"";
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
