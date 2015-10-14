//
//  NCFittingCharacterPickerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingCharacterPickerViewController.h"
#import "UIViewController+Neocom.h"
#import "NCAccountsManager.h"
#import "NCStorage.h"
#import "NCFittingCharacterEditorViewController.h"
#import "NCTableViewCell.h"
#import "UIImage+Neocom.h"
#import "UIImageView+URL.h"

@interface NCFittingCharacterPickerViewControllerRow : NSObject
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) EVECharacterSheet* characterSheet;

@end

@implementation NCFittingCharacterPickerViewControllerRow
@end

@interface NCFittingCharacterPickerViewController ()
@property (nonatomic, strong) NSMutableArray* accounts;
@property (nonatomic, strong) NSMutableArray* customCharacters;
@end

@implementation NCFittingCharacterPickerViewController

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
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.customCharacters = [[self.storageManagedObjectContext fitCharacters] mutableCopy];
	
	
	[[NCAccountsManager sharedManager] loadAccountsWithCompletionBlock:^(NSArray *accounts, NSArray *apiKeys) {
		dispatch_group_t finishDispatchGroup = dispatch_group_create();
		NSMutableArray* rows = [NSMutableArray new];
		for (NCAccount* account in accounts) {
			dispatch_group_enter(finishDispatchGroup);
			[account loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
				if (characterSheet) {
					NCFittingCharacterPickerViewControllerRow* row = [NCFittingCharacterPickerViewControllerRow new];
					row.account = account;
					row.characterSheet = characterSheet;
					@synchronized(rows) {
						[rows addObject:row];
					}
				}
				dispatch_group_leave(finishDispatchGroup);
			}];
		}
		
		dispatch_group_notify(finishDispatchGroup, dispatch_get_main_queue(), ^{
			self.accounts = rows;
			[self.tableView reloadData];
		});
	}];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	if (editing == self.editing)
		return;
	
	[super setEditing:editing animated:animated];
	double delayInSeconds = 0.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:self.customCharacters.count inSection:1];
		if (editing)
			[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
		else
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
	});
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingCharacterEditorViewController"]) {
		NCFittingCharacterEditorViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.character = sender;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return self.accounts.count;
	else if (section == 1)
		return self.editing ? self.customCharacters.count + 1 : self.customCharacters.count;
	else
		return 6;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return NSLocalizedString(@"EVE Characters", nil);
	else if (section == 1)
		return NSLocalizedString(@"Custom Characters", nil);
	else
		return NSLocalizedString(@"Built-in Characters", nil);
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1) {
		if (indexPath.row == self.customCharacters.count)
			return UITableViewCellEditingStyleInsert;
		else
			return UITableViewCellEditingStyleDelete;
	}
	else
		return UITableViewCellEditingStyleNone;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NCFitCharacter* character = self.customCharacters[indexPath.row];
		[self.customCharacters removeObjectAtIndex:indexPath.row];
		[character.managedObjectContext deleteObject:character];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		NCFitCharacter* character = [[NCFitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter"
																					   inManagedObjectContext:self.storageManagedObjectContext]
											insertIntoManagedObjectContext:self.storageManagedObjectContext];
		character.name = [NSString stringWithFormat:@"Character %d", (int32_t) self.customCharacters.count];
		[self.customCharacters addObject:character];
		[tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
		[self performSegueWithIdentifier:@"NCFittingCharacterEditorViewController" sender:character];
	}
}

#pragma mark - Table view delegate

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.editing) {
		if (indexPath.section == 0) {
			if (indexPath.section == 0) {
				NCFittingCharacterPickerViewControllerRow* row = self.accounts[indexPath.row];
				[[UIApplication sharedApplication]  beginIgnoringInteractionEvents];
				[row.account loadFitCharacterWithCompletioBlock:^(NCFitCharacter *fitCharacter) {
					[[UIApplication sharedApplication] endIgnoringInteractionEvents];
					if (fitCharacter) {
						[self performSegueWithIdentifier:@"NCFittingCharacterEditorViewController" sender:fitCharacter];
					}
				}];
			}
		}
		else {
			NCFitCharacter* character;
			if (indexPath.section == 1) {
				if (indexPath.row == self.customCharacters.count) {
					[self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
					return;
				}
				else
					character = self.customCharacters[indexPath.row];
			}
			else
				character = [self.storageManagedObjectContext fitCharacterWithSkillsLevel:indexPath.row];
			
			if (!character.managedObjectContext) {
				[self.storageManagedObjectContext insertObject:character];
				[self.customCharacters addObject:character];
				[self.customCharacters sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
				[tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.customCharacters indexOfObject:character] inSection:1]] withRowAnimation:UITableViewRowAnimationMiddle];
			}
			[self performSegueWithIdentifier:@"NCFittingCharacterEditorViewController" sender:character];
		}
	}
	else {
		if (indexPath.section == 0) {
			NCFittingCharacterPickerViewControllerRow* row = self.accounts[indexPath.row];
			[[UIApplication sharedApplication]  beginIgnoringInteractionEvents];
			[row.account loadFitCharacterWithCompletioBlock:^(NCFitCharacter *fitCharacter) {
				[[UIApplication sharedApplication] endIgnoringInteractionEvents];
				if (fitCharacter) {
					self.selectedCharacter = fitCharacter;
					[self performSegueWithIdentifier:@"Unwind" sender:fitCharacter];
				}
			}];
		}
		else {
			NCFitCharacter* character;
			if (indexPath.section == 1)
				character = self.customCharacters[indexPath.row];
			else
				character = [self.storageManagedObjectContext fitCharacterWithSkillsLevel:indexPath.row];
			self.selectedCharacter = character;
			[self performSegueWithIdentifier:@"Unwind" sender:character];
		}
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (id) identifierForSection:(NSInteger)section {
	return @(section);
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
	
	if (indexPath.section == 0) {
		NCFittingCharacterPickerViewControllerRow* row = self.accounts[indexPath.row];
		cell.titleLabel.text = row.characterSheet.name;
		cell.iconView.image = [UIImage emptyImageWithSize:CGSizeMake(32, 32)];
		[cell.iconView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:row.characterSheet.characterID size:EVEImageSizeRetina32 error:nil]];
	}
	else if (indexPath.section == 1) {
		if (indexPath.row == self.customCharacters.count) {
			cell.titleLabel.text = NSLocalizedString(@"Add Character", nil);
		}
		else {
			NCFitCharacter* character = self.customCharacters[indexPath.row];
			cell.titleLabel.text = character.name;
		}
		cell.iconView.image = nil;
	}
	else {
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"All Skills %d", nil), indexPath.row];
		cell.iconView.image = nil;
	}
}

@end
