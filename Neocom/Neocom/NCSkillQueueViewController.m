//
//  NCSkillQueueViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSkillQueueViewController.h"
#import "NCTreeSection.h"
#import "NCTreeRow.h"
#import "NCCache.h"
#import "NCDatabase.h"
#import "NCStorage.h"
#import "NCTableViewHeaderCell.h"
#import "ASBinder.h"
#import "NCManagedObjectObserver.h"
#import "NCSkill.h"

@import EVEAPI;

@interface NCSkillQueueRow : NCTreeRow
@property (nonatomic, strong) NCSkill* skill;
@end

@implementation NCSkillQueueRow
- (id) initWithSkill:(NCSkill*) skill {
	if (self = [super initWithNodeIdentifier:nil cellIdentifier:@"SkillCell"]) {
		
	}
	return self;
}
@end

@interface NCSkillQueueSection : NCTreeSection
@end

@implementation NCSkillQueueSection

- (instancetype) initWithSkillQueue:(NCCacheRecord<EVESkillQueue*>*) skillQueue {
	if (self = [super initWithNodeIdentifier:@"SkillQueue" cellIdentifier:@"NCTableViewHeaderCell"]) {
		[NCManagedObjectObserver observerWithObjectID:skillQueue.data.objectID handler:^(NSSet<NSManagedObjectID *> *updated, NSSet<NSManagedObjectID *> *deleted) {
			EVESkillQueue* queue = skillQueue.object;
			NSMutableArray<NCSkillQueueRow*>* rows = [self mutableArrayValueForKey:@"children"];
			
			NSIndexSet* set = [rows indexesOfObjectsPassingTest:^BOOL(NCSkillQueueRow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				for (EVESkillQueueItem* item in queue.skillQueue)
					if (item.typeID == obj.skill.typeID && item.level == obj.skill.level - 1)
						return NO;
				return YES;
			}];
			if (set.count > 0)
				[rows removeObjectsAtIndexes:set];
			
			for (EVESkillQueueItem* item in queue.skillQueue) {
				
			}
		}];
		EVESkillQueue* queue = skillQueue.object;
		
		NCFetchedCollection<NCDBInvType*>* invTypes = NCDatabase.sharedDatabase.invTypes;
		NSMutableArray* rows = [NSMutableArray new];
		for (EVESkillQueueItem* item in queue.skillQueue) {
			NCDBInvType* type = invTypes[item.typeID];
			NCSkill* skill = [[NCSkill alloc] initWithInvType:type skill:item inQueue:queue];
			if (type)
				[rows addObject:[[NCSkillQueueRow alloc] initWithSkill:skill]];
		}
		self.children = rows;
	}
	return self;
}

@end




@interface NCSkillQueueViewController ()

@end

@implementation NCSkillQueueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
