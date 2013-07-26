//
//  SkillsDataSource.h
//  EVEUniverse
//
//  Created by mr_depth on 23.07.13.
//
//

#import <UIKit/UIKit.h>

typedef enum {
	SkillsDataSourceModeSkillPlanner,
	SkillsDataSourceModeKnownSkills,
	SkillsDataSourceModeNotKnownSkills,
	SkillsDataSourceModeCanTrain,
	SkillsDataSourceModeAllSkills,
	SkillsDataSourceModeSkillsArray
} SkillsDataSourceMode;

@class EVEAccount;
@class EVEDBInvType;
@interface SkillsDataSource : NSObject<UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, assign) SkillsDataSourceMode mode;
@property (nonatomic, strong) NSArray* skillsArray;
@property (nonatomic, strong) EVEAccount* account;

- (void) reload;
- (EVEDBInvType*) skillAtIndexPath:(NSIndexPath*) indexPath;
@end
