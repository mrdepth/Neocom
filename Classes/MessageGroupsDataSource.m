//
//  MessageGroupsDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 25.08.13.
//
//

#import "MessageGroupsDataSource.h"
#import "EUOperationQueue.h"
#import "EUMailBox.h"
#import "EVEAccount.h"
#import "UIAlertView+Error.h"
#import "GroupedCell.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface MessageGroupsDataSource()
@property (nonatomic, strong) NSMutableArray* groups;

@end

@implementation MessageGroupsDataSource

- (void) reload {
	EUMailBox* mailBox = self.mailBox;
	NSMutableArray* groupsTmp = [NSMutableArray new];
	EUOperation *operation = [EUOperation operationWithIdentifier:@"MessageGroupsDataSource+reload" name:NSLocalizedString(@"Loading Messages", nil)];
	EVEAccount* account = [EVEAccount currentAccount];
	
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NSMutableDictionary* personal = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableArray new], @"messages", @(0), @"unread", @"Inbox", @"title", nil];
		NSMutableDictionary* groups = [NSMutableDictionary new];
		NSString* characterID = [NSString stringWithFormat:@"%d", account.character.characterID];
		
		for (EUMailMessage* message in mailBox.inbox) {
			BOOL isPersonal = [message.header.toCharacterIDs containsObject:characterID];
			if (isPersonal) {
				[personal[@"messages"] addObject:message];
				if (!message.read)
					personal[@"unread"] = @([personal[@"unread"] integerValue] + 1);
			}
			else {
				NSMutableDictionary* group = groups[message.to];
				if (!group)
					groups[message.to] = group = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableArray new], @"messages", @(0), @"unread", message.to, @"title", nil];
				if (!message.read)
					group[@"unread"] = @([group[@"unread"] integerValue] + 1);
				[group[@"messages"] addObject:message];
				
			}
		}
		[groupsTmp addObject:personal];
		[groupsTmp addObjectsFromArray:[[groups allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]]];
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			self.groups = groupsTmp;
			[self.tableView reloadData];
		}
	}];
		
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? self.groups.count : 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
    
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	if (indexPath.section == 0) {
		NSDictionary* group = self.groups[indexPath.row];
		NSInteger unread = [group[@"unread"] integerValue];
		cell.textLabel.text = group[@"title"];
		if (unread > 0)
			cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d unread messages", nil), unread];
		else
			cell.detailTextLabel.text = nil;
	}
	else {
		cell.textLabel.text = NSLocalizedString(@"Sent", nil);
		cell.detailTextLabel.text = nil;
	}
    
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section == 0 ? NSLocalizedString(@"Inbox", nil) : NSLocalizedString(@"Sent", nil);
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 40;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		NSDictionary* group = self.groups[indexPath.row];
		[self.delegate messageGroupsDataSource:self didSelectGroup:group[@"messages"] withTitle:group[@"title"]];
	}
	else
		[self.delegate messageGroupsDataSource:self didSelectGroup:self.mailBox.sent withTitle:NSLocalizedString(@"Sent", nil)];
}

@end
