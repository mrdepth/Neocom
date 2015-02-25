//
//  NCSettingsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 27.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSettingsViewController.h"
#import "NCNotificationsManager.h"
#import "NCMainMenuViewController.h"
#import "UIAlertView+Block.h"
#import "NCCache.h"
#import "NCAppDelegate.h"
#import "UIColor+Neocom.h"
#import "UIColor+Neocom.h"

@interface NCSettingsViewController ()

@end

@implementation NCSettingsViewController

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
	NCNotificationsManagerSkillQueueNotificationTime notificationTime = [[NSUserDefaults standardUserDefaults] integerForKey:NCSettingsSkillQueueNotificationTimeKey];
	self.notification24HoursSwitch.on = (notificationTime & NCNotificationsManagerSkillQueueNotificationTime1Day) == NCNotificationsManagerSkillQueueNotificationTime1Day;
	self.notification12HoursSwitch.on = (notificationTime & NCNotificationsManagerSkillQueueNotificationTime12Hours) == NCNotificationsManagerSkillQueueNotificationTime12Hours;
	self.notification4HoursSwitch.on = (notificationTime & NCNotificationsManagerSkillQueueNotificationTime4Hours) == NCNotificationsManagerSkillQueueNotificationTime4Hours;
	self.notification1HourSwitch.on = (notificationTime & NCNotificationsManagerSkillQueueNotificationTime1Hour) == NCNotificationsManagerSkillQueueNotificationTime1Hour;

	NCMarketPricesMonitor marketPricesMonitor = [[NSUserDefaults standardUserDefaults] integerForKey:NCSettingsMarketPricesMonitorKey];
	self.exchangeRateSwitch.on = (marketPricesMonitor & NCMarketPricesMonitorExchangeRate) == NCMarketPricesMonitorExchangeRate;
	self.plexSwitch.on = (marketPricesMonitor & NCMarketPricesMonitorPlex) == NCMarketPricesMonitorPlex;
	self.mineralsSwitch.on = (marketPricesMonitor & NCMarketPricesMonitorMinerals) == NCMarketPricesMonitorMinerals;
	self.iCloudSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsUseCloudKey];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onChangeNotification:(id)sender {
	NCNotificationsManagerSkillQueueNotificationTime notificationTime = 0;
	notificationTime |= self.notification24HoursSwitch.on ? NCNotificationsManagerSkillQueueNotificationTime1Day : 0;
	notificationTime |= self.notification12HoursSwitch.on ? NCNotificationsManagerSkillQueueNotificationTime12Hours : 0;
	notificationTime |= self.notification4HoursSwitch.on ? NCNotificationsManagerSkillQueueNotificationTime4Hours : 0;
	notificationTime |= self.notification1HourSwitch.on ? NCNotificationsManagerSkillQueueNotificationTime1Hour : 0;
	[[NSUserDefaults standardUserDefaults] setInteger:notificationTime forKey:NCSettingsSkillQueueNotificationTimeKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:NCSkillQueueNotificationTimeDidChangeNotification object:nil userInfo:nil];
}

- (IBAction)onChangeMarketPricesMonitor:(id)sender {
	NCMarketPricesMonitor marketPricesMonitor = 0;
	marketPricesMonitor |= self.exchangeRateSwitch.on ? NCMarketPricesMonitorExchangeRate : 0;
	marketPricesMonitor |= self.plexSwitch.on ? NCMarketPricesMonitorPlex : 0;
	marketPricesMonitor |= self.mineralsSwitch.on ? NCMarketPricesMonitorMinerals : 0;
	[[NSUserDefaults standardUserDefaults] setInteger:marketPricesMonitor forKey:NCSettingsMarketPricesMonitorKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:NCMarketPricesMonitorDidChangeNotification object:nil userInfo:nil];
}

- (IBAction)onChangeCloud:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:NCSettingsUseCloudKey];
	NCAppDelegate* delegate = (NCAppDelegate*)[[UIApplication sharedApplication] delegate];
	[delegate reconnectStoreIfNeeded];
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 1) {
		[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Clear Cache?", nil)
								 message:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
					   otherButtonTitles:@[NSLocalizedString(@"Clear", nil)]
						 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex != alertView.cancelButtonIndex) {
								 [[NSURLCache sharedURLCache] removeAllCachedResponses];
								 [[NCCache sharedCache] clear];
							 }
						 }
							 cancelBlock:nil] show];
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
