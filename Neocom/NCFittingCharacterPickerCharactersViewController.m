//
//  NCFittingCharacterPickerCharactersViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingCharacterPickerCharactersViewController.h"
#import "NCFittingCharacterPickerViewController.h"
#import "NCAccountsManager.h"
#import "NCFitCharacter.h"
#import "NCTableViewCell.h"
#import "UIImageView+URL.h"
#import "UIImage+Neocom.h"

@interface NCFittingCharacterPickerViewController ()
@property (nonatomic, copy) void (^completionHandler)(NCFitCharacter* character);
@end


@interface NCFittingCharacterPickerCharactersViewController ()
@property (nonatomic, strong) NSMutableArray* accounts;
@property (nonatomic, strong) NSMutableArray* customCharacters;
@end

@implementation NCFittingCharacterPickerCharactersViewController

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
	self.refreshControl = nil;
	
	NSMutableArray* accounts = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 for (NCAccount* account in [[NCAccountsManager defaultManager] accounts]) {
												 if (account.characterSheet)
													 [accounts addObject:account];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 self.accounts = accounts;
								 [self.tableView reloadData];
							 }];
	
	self.customCharacters = [NSMutableArray arrayWithArray:[NCFitCharacter characters]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return self.accounts.count;
	else if (section == 1)
		return self.customCharacters.count;
	else
		return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (indexPath.section == 0) {
		NCAccount* account = self.accounts[indexPath.row];
		cell.textLabel.text = account.characterSheet.name;
		cell.imageView.image = [UIImage emptyImage];
		[cell.imageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSizeRetina32 error:nil]];
	}
	else if (indexPath.section == 1) {
		NCFitCharacter* character = self.customCharacters[indexPath.row];
		cell.textLabel.text = character.name;
		cell.imageView.image = nil;
	}
	else {
		cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"All Skills %d", nil), indexPath.row];
		cell.imageView.image = nil;
	}
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return NSLocalizedString(@"EVE Characters", nil);
	else if (section == 1)
		return NSLocalizedString(@"Custom Characters", nil);
	else
		return NSLocalizedString(@"Built-in Characters", nil);
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFitCharacter* character;
	if (indexPath.section == 0)
		character = [NCFitCharacter characterWithAccount:self.accounts[indexPath.row]];
	else if (indexPath.section == 1)
		character = self.customCharacters[indexPath.row];
	else
		character = [NCFitCharacter characterWithSkillsLevel:indexPath.row];
	
	NCFittingCharacterPickerViewController* controller = (NCFittingCharacterPickerViewController*) self.navigationController;
	controller.completionHandler(character);
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
