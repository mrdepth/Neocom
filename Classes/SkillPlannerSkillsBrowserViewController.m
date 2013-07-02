//
//  SkillPlannerSkillsBrowserViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 20.06.13.
//
//

#import "SkillPlannerSkillsBrowserViewController.h"
#import "EVEDBAPI.h"
#import "EUOperationQueue.h"
#import "UIAlertView+Error.h"
#import "EVEAccount.h"
#import "NSString+TimeLeft.h"
#import "NSNumberFormatter+Neocom.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "SkillCellView.h"
#import "UITableViewCell+Nib.h"
#import "UIImageView+GIF.h"
#import "ItemViewController.h"

@interface SkillPlannerSkillsBrowserViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSArray* filteredSections;
- (void) reload;
- (void) filter;
@end

@implementation SkillPlannerSkillsBrowserViewController

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
	self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	self.title = NSLocalizedString(@"Skills", nil);
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil)
																			 style:UIBarButtonItemStyleBordered
																			target:self
																			action:@selector(onClose:)];
	[self reload];
	self.navigationItem.titleView = self.filterSegmentedControl;
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

- (void)viewDidUnload {
	[self setFilterSegmentedControl:nil];
	[super viewDidUnload];
}

- (IBAction)onChangeFilter:(id)sender {
	[self filter];
}

- (IBAction)onClose:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.filteredSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.filteredSections[section][@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"SkillCellView";
    
    SkillCellView *cell = (SkillCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [SkillCellView cellWithNibName:@"SkillCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *skill = self.filteredSections[indexPath.section][@"rows"][indexPath.row];

	NSString* iconImageName = skill[@"iconImageName"];
	if (!iconImageName)
		iconImageName = @"Icons/icon50_11.png";

	cell.iconImageView.image = [UIImage imageNamed:iconImageName];
	NSString* levelImagePath = [[NSBundle mainBundle] pathForResource:skill[@"levelImageName"] ofType:nil];
	if (levelImagePath)
		[cell.levelImageView setGIFImageWithContentsOfURL:[NSURL fileURLWithPath:levelImagePath]];
	else
		[cell.levelImageView setImage:nil];
	cell.skillLabel.text = skill[@"title"];
	cell.skillPointsLabel.text = skill[@"skillPoints"];
	cell.levelLabel.text = skill[@"level"];
	cell.remainingLabel.text = skill[@"remainingTime"];
	
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.filteredSections[section][@"groupName"];
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.collapsed = NO;
		view.titleLabel.text = title;
		
		view.collapsed = [self tableView:tableView sectionIsCollapsed:section];
		return view;
	}
	else
		return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	EVEDBInvType* skill = self.filteredSections[indexPath.section][@"rows"][indexPath.row][@"type"];
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = skill;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - CollapsableTableViewDelegate

- (BOOL) tableView:(UITableView *)tableView sectionIsCollapsed:(NSInteger) section {
	return [self.filteredSections[section][@"collapsed"] boolValue];
}

- (BOOL) tableView:(UITableView *)tableView canCollapsSection:(NSInteger) section {
	return YES;
}

- (void) tableView:(UITableView *)tableView didCollapsSection:(NSInteger) section {
	self.filteredSections[section][@"collapsed"] = @(YES);
}

- (void) tableView:(UITableView *)tableView didExpandSection:(NSInteger) section {
	self.filteredSections[section][@"collapsed"] = @(NO);
}

#pragma mark - Private

- (void) reload {
	NSMutableArray *sectionsTmp = [NSMutableArray array];

	__block NSError *error = nil;
	EUOperation *operation = [EUOperation operationWithIdentifier:@"SkillPlannerSkillsBrowserViewController+reload" name:NSLocalizedString(@"Loading Skills", nil)];
	__weak EUOperation* weakOperation;
	[operation addExecutionBlock:^(void) {
		
		EVEAccount *account = [EVEAccount currentAccount];
		if (!account)
			return;
		
		account.skillQueue = [EVESkillQueue skillQueueWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID error:&error progressHandler:nil];
		weakOperation.progress = 0.3;
		
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			NSDate *currentTime = [account.skillQueue serverTimeWithLocalTime:[NSDate date]];
			
			NSMutableDictionary* groups = [[NSMutableDictionary alloc] init];
			NSMutableDictionary* skills = [[NSMutableDictionary alloc] init];
			
			[[EVEDBDatabase sharedDatabase] execSQLRequest:@"SELECT a.* FROM invTypes as a, invGroups as b where a.groupID=b.groupID and b.categoryID=16 and a.published = 1 order by typeName;"
											   resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
												   if ([weakOperation isCancelled])
													   *needsMore = NO;

												   EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
												   NSMutableDictionary* group = groups[@(type.groupID)];
												   if (!group) {
													   groups[@(type.groupID)] = group = [[NSMutableDictionary alloc] init];
													   group[@"rows"] = [NSMutableArray array];
												   }
												   
												   NSMutableDictionary* skill = [[NSMutableDictionary alloc] init];
												   skill[@"type"] = type;
												   
												   EVEDBDgmTypeAttribute *attribute = [[type attributesDictionary] valueForKey:@"275"];
												   skill[@"title"] = [NSString stringWithFormat:@"%@ (x%d)", type.typeName, (int) attribute.value];
												   skill[@"trainedLevel"] = @(-1);

												   [group[@"rows"] addObject:skill];
												   group[@"groupName"] = type.group.groupName;
												   skills[@(type.typeID)] = skill;
											   }];
			
			
			weakOperation.progress = 0.3;
			int i = 0;
			for (EVESkillQueueItem *item in account.skillQueue.skillQueue) {
				NSMutableDictionary* skill = skills[@(item.typeID)];
				if (!skill)
					continue;
				EVEDBInvType* type = skill[@"type"];
				skill[@"targetLevel"] = @(item.level);
				if (!skill[@"startSkillPoints"])
					skill[@"startSkillPoints"] = @([type skillpointsAtLevel:item.level - 1]);
				skill[@"targetSkillPoints"] = @(item.endSP);
				
				skill[@"iconImageName"] = @"Icons/icon50_12.png";
				skill[@"active"] = @(i == 0);
				
				
				if (item.endTime) {
					NSTimeInterval remainingTime = [item.endTime timeIntervalSinceDate:i == 0 ? currentTime : item.startTime];
					skill[@"remainingTime"] = [NSString stringWithTimeLeft:remainingTime];
				}
				i++;
			}
			
			weakOperation.progress = 0.5;
			if (account.characterSheet.skills) {
				for (EVECharacterSheetSkill *item in account.characterSheet.skills) {
					NSMutableDictionary* skill = skills[@(item.typeID)];
					EVEDBInvType* type = skill[@"type"];
					skill[@"trainedLevel"] = @(item.level);
					skill[@"level"] = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), item.level];

					skill[@"skillPoints"] = [NSString stringWithFormat:NSLocalizedString(@"SP: %@", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:item.skillpoints]];
					if (skill[@"targetLevel"]) {
						int progress;
						int targetLevel = [skill[@"targetLevel"] integerValue];
						int startSkillPoints = [skill[@"startSkillPoints"] integerValue];
						int targetSkillPoints = [skill[@"targetSkillPoints"] integerValue];

						if (targetLevel == item.level + 1)
							progress = (item.skillpoints - startSkillPoints) * 100 / (targetSkillPoints - startSkillPoints);
						else
							progress = 0;
						
						if (progress > 100)
							progress = 100;
						if (skill[@"remainingTime"])
							skill[@"remainingTime"] = [NSString stringWithFormat:@"%@ (%d%%)", skill[@"remainingTime"], progress];
					}
					BOOL isActive = [skill[@"active"] boolValue];
					
					skill[@"iconImageName"] = isActive ? @"Icons/icon50_12.png" : (item.level == 5 ? @"Icons/icon50_14.png" : @"Icons/icon50_13.png");
					skill[@"levelImageName"] = [NSString stringWithFormat:@"level_%d%d%d.gif", item.level, [skill[@"targetLevel"] integerValue], isActive];

					NSMutableDictionary* group = groups[@(type.groupID)];
					group[@"skillPoints"] = @([group[@"skillPoints"] integerValue] + item.skillpoints);
				}
			}
			
			[sectionsTmp addObjectsFromArray:[[groups allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES]]]];
			for (NSDictionary *group in sectionsTmp) {
				[group setValue:[NSString stringWithFormat:NSLocalizedString(@"%@ (%@ skillpoints)", nil),
								 group[@"groupName"],
								 [NSNumberFormatter neocomLocalizedStringFromInteger:[group[@"skillPoints"] integerValue]]]
						 forKey:@"groupName"];
			}
			weakOperation.progress = 1.0;
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			if (error) {
				[UIAlertView alertViewWithError:error];
			}
			else {
				
			}
		}
		self.sections = sectionsTmp;
		[self filter];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) filter {
	if (!self.sections)
		return;
	
	NSMutableArray *filteredSectionsTmp = [NSMutableArray array];
	NSArray* sections = self.sections;
	int selectedSegmentIndex = self.filterSegmentedControl.selectedSegmentIndex;
	
	EUOperation *operation = [EUOperation operationWithIdentifier:@"SkillPlannerSkillsBrowserViewController+filter" name:NSLocalizedString(@"Loading Skills", nil)];
	__weak EUOperation* weakOperation;
	[operation addExecutionBlock:^(void) {
		NSPredicate* predicate = nil;
		if (selectedSegmentIndex == 1)
			predicate = [NSPredicate predicateWithFormat:@"trainedLevel < 5 AND trainedLevel >= 0"];
		else if (selectedSegmentIndex == 2)
			predicate = [NSPredicate predicateWithFormat:@"trainedLevel < 0"];
		
		for (NSDictionary* section in sections) {
			NSArray* rows = predicate ? [section[@"rows"] filteredArrayUsingPredicate:predicate] : section[@"rows"];
			if (rows.count > 0) {
				NSMutableDictionary* filteredSection = [NSMutableDictionary dictionaryWithDictionary:section];
				filteredSection[@"rows"] = rows;
				[filteredSectionsTmp addObject:filteredSection];
			}
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
		}
		self.filteredSections = filteredSectionsTmp;
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}
@end
