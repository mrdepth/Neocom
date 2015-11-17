//
//  NCFittingCRESTAccountsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 06.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingCRESTAccountsViewController.h"
#import <EVEAPI/EVEAPI.h>
#import "UIImageView+URL.h"
#import "NCSetting.h"
#import "NSManagedObjectContext+NCStorage.h"
#import "UIImage+Neocom.h"
#import "UIAlertController+Neocom.h"
#import "NCFittingCRESTFitsViewController.h"

@interface NCFittingCRESTAccountsViewController ()
@property (nonatomic, strong) NSMutableArray* tokens;
- (void) reload;
@end

@implementation NCFittingCRESTAccountsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	[self reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingCRESTFitsViewController"]) {
		NCFittingCRESTFitsViewController* controller = segue.destinationViewController;
		controller.token = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return section == 0 ? self.tokens.count : 1;
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
	if (indexPath.section == 1) {
		CRAPI* api = [CRAPI apiWithCachePolicy:NSURLRequestUseProtocolCachePolicy clientID:CRAPIClientID secretKey:CRAPISecretKey token:nil callbackURL:[NSURL URLWithString:CRAPICallbackURLString]];
		[api authenticateWithCompletionBlock:^(CRToken *token, NSError *error) {
			if (token) {
				[self.storageManagedObjectContext settingWithKey:[NSString stringWithFormat:@"sso.%d", token.characterID]].value = token;
				[self.storageManagedObjectContext save:nil];
				[self reload];
			}
			else if (error)
				[self presentViewController:[UIAlertController alertWithError:error] animated:YES completion:nil];
		}];
	}
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0 ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		CRToken* token = self.tokens[indexPath.row];
		NCSetting* setting = [self.storageManagedObjectContext settingWithKey:[NSString stringWithFormat:@"sso.%d", token.characterID]];
		[self.storageManagedObjectContext deleteObject:setting];
		[self.storageManagedObjectContext save:nil];
		[self.tokens removeObjectAtIndex:indexPath.row];
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - NCTableViewController

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0)
		return @"Cell";
	else
		return @"LoginCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.section == 0) {
		NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
		CRToken* token = self.tokens[indexPath.item];
		cell.titleLabel.text = token.characterName;
		cell.iconView.image = [UIImage emptyImageWithSize:CGSizeMake(32, 32)];
		[cell.iconView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:token.characterID size:EVEImageSizeRetina32 error:nil]];
		cell.object = token;
	}
}

#pragma mark - Private

- (void) reload {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Setting"];
	request.predicate = [NSPredicate predicateWithFormat:@"key BEGINSWITH \"sso\""];
	NSMutableArray* tokens = [NSMutableArray new];
	for (NCSetting* setting in [self.storageManagedObjectContext executeFetchRequest:request error:nil]) {
		CRToken* token = setting.value;
		if (token)
			[tokens addObject:token];
	}
	[tokens sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"characterName" ascending:YES]]];
	self.tokens = tokens;
	[self.tableView reloadData];
}

@end
