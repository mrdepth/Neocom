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
#import "NCCache.h"
#import "NCAppDelegate.h"
#import "UIColor+Neocom.h"
#import "NCUpdater.h"

@interface NCSettingsViewController ()
- (void) update;
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
	self.loadImplantsSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsLoadCharacterImplantsKey];
	self.saveChangesPromptSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsDisableSaveChangesPromptKey];

	NCDBVersion* version = [self.databaseManagedObjectContext version];
	self.databaseCell.textLabel.text = [NSString stringWithFormat:@"%@ %@", version.expansion, version.version];
	[self update];
	
	NCUpdater* updater = [NCUpdater sharedUpdater];
	[updater addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
	[updater.progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:nil];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) dealloc {
	NCUpdater* updater = [NCUpdater sharedUpdater];
	[updater removeObserver:self forKeyPath:@"state"];
	[updater.progress removeObserver:self forKeyPath:@"fractionCompleted"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self update];
	});
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

- (IBAction)onChangeLoadImplants:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:NCSettingsLoadCharacterImplantsKey];
}

- (IBAction)onChangeSaveChangesPrompt:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:NCSettingsDisableSaveChangesPromptKey];
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 1) {
		UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Clear Cache?", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Clear", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[[NSURLCache sharedURLCache] removeAllCachedResponses];
			[[NCCache sharedCache] clear];
		}]];
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
		[self presentViewController:controller animated:YES completion:nil];
	}
	else if (indexPath.section == 2) {
		NCUpdater* updater = [NCUpdater sharedUpdater];
		if (updater.state == NCUpdaterStateWaitingForDownload || updater.state == NCUpdaterStateWaitingForInstall) {
			[updater download];
		}
	}
/*	else if (indexPath.section == 0) {
		if (indexPath.row == 1) {
			[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Backup", nil)
									 message:NSLocalizedString(@"Do you wish to transfer data from iCloud to Local Storage.", nil)
						   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
						   otherButtonTitles:@[NSLocalizedString(@"Backup", nil)]
							 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
								 if (alertView.cancelButtonIndex != selectedButtonIndex) {
									 BOOL b = [[NCStorage sharedStorage] backupCloudData];
									 [[UIAlertView alertViewWithTitle:NSLocalizedString(@"Backup", nil)
															  message:b ? NSLocalizedString(@"Backup finished", nil) : NSLocalizedString(@"Unable to transfer data", nil)
													cancelButtonTitle:NSLocalizedString(@"Close", nil)
													otherButtonTitles:nil
													  completionBlock:nil
														  cancelBlock:nil] show];
								 }
							 }
								 cancelBlock:nil] show];
		}
		else if (indexPath.row == 2) {
			[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Restore", nil)
									 message:NSLocalizedString(@"Do you wish to transfer data from Local Storage to iCloud.", nil)
						   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
						   otherButtonTitles:@[NSLocalizedString(@"Restore", nil)]
							 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
								 if (alertView.cancelButtonIndex != selectedButtonIndex) {
									 BOOL b = [[NCStorage sharedStorage] restoreCloudData];
									 [[UIAlertView alertViewWithTitle:NSLocalizedString(@"Restore", nil)
															  message:b ? NSLocalizedString(@"Restore finished", nil) : NSLocalizedString(@"Unable to transfer data", nil)
													cancelButtonTitle:NSLocalizedString(@"Close", nil)
													otherButtonTitles:nil
													  completionBlock:nil
														  cancelBlock:nil] show];
								 }
							 }
								 cancelBlock:nil] show];
		}
	}*/
}

#pragma mark - Private

- (void) update {
	NCUpdater* updater = [NCUpdater sharedUpdater];
	NSString* updateName = updater.updateName ? [NSString stringWithFormat:NSLocalizedString(@"%@ (%.1f MiB)", nil), updater.updateName, updater.updateSize / 1024.0f / 1024.0f] : @"Update";
	
	switch (updater.state) {
		case NCUpdaterStateWaitingForDownload:
			self.databaseCell.detailTextLabel.text = [updater.error localizedDescription] ?: [NSString stringWithFormat:NSLocalizedString(@"Click here to download %@", nil), updateName];
//			break;
		case NCUpdaterStateWaitingForInstall:
			self.databaseCell.detailTextLabel.text = [updater.error localizedDescription] ?: [NSString stringWithFormat:NSLocalizedString(@"Click here to download %@", nil), updateName];
			break;
		case NCUpdaterStateDownloading:
			self.databaseCell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@: downloading %.0f%%", nil), updateName, updater.progress.fractionCompleted * 100.0f];
			break;
		case NCUpdaterStateInstalling:
			self.databaseCell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@: installing %.0f%%", nil), updateName, updater.progress.fractionCompleted * 100.0f];
			break;
		default: {
			NCDBVersion* version = [self.databaseManagedObjectContext version];
			self.databaseCell.textLabel.text = [NSString stringWithFormat:@"%@ %@", version.expansion, version.version];
			self.databaseCell.detailTextLabel.text = NSLocalizedString(@"Your database is up to date", nil);
			break;
		}
	}
}

@end
