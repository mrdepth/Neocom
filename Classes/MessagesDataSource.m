//
//  MessagesDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 27.08.13.
//
//

#import "MessagesDataSource.h"
#import "MessageCellView.h"
#import "UITableViewCell+Nib.h"
#import "EUMailMessage.h"
#import "EVEOnlineAPI.h"

@implementation MessagesDataSource

- (void) reload {
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.messages.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"MessageCellView";
	
    MessageCellView *cell = (MessageCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell = [MessageCellView cellWithNibName:@"MessageCellView" bundle:nil reuseIdentifier:cellIdentifier];
	
	EUMailMessage *message = self.messages[indexPath.row];
	UIFont* font = message.read ?
		[UIFont systemFontOfSize:cell.subjectLabel.font.pointSize] :
		[UIFont boldSystemFontOfSize:cell.subjectLabel.font.pointSize];
	
	UIColor* color = message.read ? [UIColor lightTextColor] : [UIColor whiteColor];
	cell.subjectLabel.text = message.header.title;
	cell.fromLabel.text = [NSString stringWithFormat:@"%@ -> %@", message.from, message.to];
	
	cell.subjectLabel.font = font;
	cell.subjectLabel.textColor = color;
	cell.fromLabel.font = font;
	cell.fromLabel.textColor = color;
	cell.dateLabel.font = font;
	cell.dateLabel.textColor = color;
	
	cell.dateLabel.text = message.date;

	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 0;
//	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 54;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	EUMailMessage *message = self.messages[indexPath.row];
	[self.delegate messageDataSource:self didSelectMessage:message];
/*	if (indexPath.section == 0) {
		NSDictionary* group = self.groups[indexPath.row];
		[self.delegate messageGroupsDataSource:self didSelectGroup:group[@"messages"] withTitle:group[@"title"]];
	}
	else
		[self.delegate messageGroupsDataSource:self didSelectGroup:self.mailBox.sent withTitle:NSLocalizedString(@"Sent", nil)];*/
}

@end
