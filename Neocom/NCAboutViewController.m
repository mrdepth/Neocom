//
//  NCAboutViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 06.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAboutViewController.h"
#import "UIAlertView+Block.h"
#import "NCCache.h"

@interface NCAboutViewController ()

@end

@implementation NCAboutViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	self.versionLabel.text = [NSString stringWithFormat:@"%@", [info valueForKey:@"CFBundleVersion"]];
	self.sdeVersionLabel.text = @"Phoebe 1.0";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 2) {
		if (indexPath.row == 1)
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.eveuniverseiphone.com"]];
		else if (indexPath.row == 2)
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:support@eveuniverseiphone.com"]];
		else if (indexPath.row == 3)
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/mrdepth"]];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
