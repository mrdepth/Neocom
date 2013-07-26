//
//  SkillPlan.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import "SkillPlan.h"
#import "EUStorage.h"
#import "EVEAccount.h"
#import "TrainingQueue.h"

@interface SkillPlan()
- (void) didUpdateCloud:(NSNotification*) notification;
@end

@implementation SkillPlan

@dynamic attributes;
@dynamic characterID;
@dynamic skillPlanName;
@dynamic skillPlanSkills;

@synthesize skills = _skills;
@synthesize trainingTime = _trainingTime;
@synthesize characterAttributes = _characterAttributes;
@synthesize characterSkills = _characterSkills;
@synthesize name = _name;

+ (id) skillPlanWithAccount:(EVEAccount*) account name:(NSString*) name {
	if (!account || !account.character)
		return nil;
	
	EUStorage* storage = [EUStorage sharedStorage];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID = %d AND skillPlanName == %@", account.character.characterID, name];
	[fetchRequest setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	SkillPlan* skillPlan;
	if (fetchedObjects.count > 0) {
		skillPlan = [fetchedObjects objectAtIndex:0];
		skillPlan.characterAttributes = [account characterAttributes];
		skillPlan.characterSkills = account.characterSheet.skillsMap;
	}
	else {
		skillPlan = [[SkillPlan alloc] initWithAccount:account];
		skillPlan.skillPlanName = name;
	}
	return skillPlan;
}

+ (id) skillPlanWithAccount:(EVEAccount*) account eveMonSkillPlanPath:(NSString*) skillPlanPath {
	SkillPlan* skillPlan = [self skillPlanWithAccount:account name:nil];
	NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL fileURLWithPath:skillPlanPath]];
	parser.delegate = skillPlan;
	if (![parser parse]) {
		return nil;
	}
	return skillPlan;
}

+ (id) skillPlanWithAccount:(EVEAccount*) account eveMonSkillPlan:(NSString*) eveMonSkillPlan {
	SkillPlan* skillPlan = [self skillPlanWithAccount:account name:nil];
	NSXMLParser* parser = [[NSXMLParser alloc] initWithData:[eveMonSkillPlan dataUsingEncoding:NSUTF8StringEncoding]];
	parser.delegate = skillPlan;
	if (![parser parse]) {
		return nil;
	}
	return skillPlan;
}

- (id) initWithAccount:(EVEAccount*) aAccount {
	if (self = [self init]) {
		if (!aAccount) {
			return nil;
		}
		self.skills = [NSMutableArray array];
		_trainingTime = -1;
		
		self.characterAttributes = [aAccount characterAttributes];
		self.characterSkills = aAccount.characterSheet.skillsMap;
		self.characterID = aAccount.characterID;
	}
	return self;
}

- (id) init {
	EUStorage* storage = [EUStorage sharedStorage];
	if (self = [super initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:nil]) {
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateCloud:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];

		self.skills = [NSMutableArray array];
		_trainingTime = -1;
		self.characterID = 0;
		self.characterAttributes = [CharacterAttributes defaultCharacterAttributes];
	}
	return self;
}

- (void) awakeFromFetch {
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateCloud:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];

	self.skills = [NSMutableArray array];
}

- (void) dealloc {
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];
}

- (NSMutableArray*) skills {
	if (!_skills) {
		_skills = [[NSMutableArray alloc] init];
	}
	return _skills;
}

- (void) setSkills:(NSMutableArray *)skills {
	_skills = skills;
	_trainingTime = -1;
}

- (void) addSkill:(EVEDBInvTypeRequiredSkill*) skill {
	EVECharacterSheetSkill *characterSkill = self.characterSkills[@(skill.typeID)];
	if (characterSkill.level >= skill.requiredLevel)
		return;
	
	BOOL addedDependence = NO;
	for (NSInteger level = characterSkill.level + 1; level <= skill.requiredLevel; level++) {
		BOOL isExist = NO;
		for (EVEDBInvTypeRequiredSkill *item in self.skills) {
			if (item.typeID == skill.typeID && item.requiredLevel == level) {
				isExist = YES;
				break;
			}
		}
		if (!isExist) {
			if (!addedDependence) {
				[self addType:skill];
				addedDependence = YES;
			}
			EVEDBInvTypeRequiredSkill* requiredSkill = [EVEDBInvTypeRequiredSkill invTypeWithTypeID:skill.typeID error:nil];
			requiredSkill.requiredLevel = level;
			requiredSkill.currentLevel = characterSkill.level;
			float sp = [requiredSkill skillPointsAtLevel:level - 1];
			requiredSkill.currentSP = MAX(sp, characterSkill.skillpoints);
			[self.skills addObject:requiredSkill];
			[[NSNotificationCenter defaultCenter] postNotificationName:NotificationSkillPlanDidAddSkill object:self userInfo:[NSDictionary dictionaryWithObject:requiredSkill forKey:@"skill"]];
		}
	}
	_trainingTime = -1;
}

- (void) addType:(EVEDBInvType*) type {
	for (EVEDBInvTypeRequiredSkill* skill in type.requiredSkills)
		[self addSkill:skill];
}

- (void) addCertificate:(EVEDBCrtCertificate*) certificate {
	for (EVEDBCrtRelationship* relationship in certificate.prerequisites) {
		if (relationship.parent)
			[self addCertificate:relationship.parent];
		else if (relationship.parentType)
			[self addSkill:relationship.parentType];
	}
}

- (void) removeSkill:(EVEDBInvTypeRequiredSkill*) skill {
	NSInteger typeID = skill.typeID;
	NSInteger level = skill.requiredLevel;
	NSInteger index = 0;
	NSMutableIndexSet* indexes = [NSMutableIndexSet indexSet];
	for (EVEDBInvTypeRequiredSkill* requiredSkill in self.skills) {
		if (requiredSkill.typeID == typeID && requiredSkill.requiredLevel >= level) {
			_trainingTime -= (requiredSkill.requiredSP - requiredSkill.currentSP) / [self.characterAttributes skillpointsPerSecondForSkill:requiredSkill];
			[indexes addIndex:index];
		}
		index++;
	}
	[self.skills removeObjectsAtIndexes:indexes];
	if (indexes.count > 0)
		[[NSNotificationCenter defaultCenter] postNotificationName:NotificationSkillPlanDidRemoveSkill object:self userInfo:@{@"indexes" : indexes}];
}

- (NSTimeInterval) trainingTime {
	if (_trainingTime < 0) {
		_trainingTime = 0;
		
		for (EVEDBInvTypeRequiredSkill *skill in self.skills) {
			if (skill.currentLevel < skill.requiredLevel)
				_trainingTime += (skill.requiredSP - skill.currentSP) / [self.characterAttributes skillpointsPerSecondForSkill:skill];
		}
	}
	return _trainingTime;
}

- (void) reload {
	
}

- (void) resetTrainingTime {
	_trainingTime = -1;
	for (EVEDBInvTypeRequiredSkill* skill in self.skills) {
		EVECharacterSheetSkill *characterSkill = self.characterSkills[@(skill.typeID)];
		float sp = [skill skillPointsAtLevel:skill.requiredLevel - 1];
		skill.currentSP = MAX(sp, characterSkill.skillpoints);
	}
}

- (void) save {
	if (!self.characterID)
		return;
	EUStorage* storage = [EUStorage sharedStorage];
	[storage.managedObjectContext performBlockAndWait:^{
		NSMutableString* s = [NSMutableString string];
		BOOL isFirst = YES;
		for (EVEDBInvTypeRequiredSkill* skill in self.skills) {
			if (isFirst) {
				[s appendFormat:@"%d:%d", skill.typeID, skill.requiredLevel];
				isFirst = NO;
			}
			else {
				[s appendFormat:@";%d:%d", skill.typeID, skill.requiredLevel];
			}
		}
		
		if (![self.skillPlanSkills isEqualToString:s])
			self.skillPlanSkills = s;
		
		if (![self managedObjectContext])
			[storage.managedObjectContext insertObject:self];
		[storage saveContext];
	}];
}

- (void) load {
	EUStorage* storage = [EUStorage sharedStorage];

	[storage.managedObjectContext performBlockAndWait:^{
		if (!self.skills)
			self.skills = [NSMutableArray array];
		else
			[self.skills removeAllObjects];
		_trainingTime = -1;
		for (NSString* row in [self.skillPlanSkills componentsSeparatedByString:@";"]) {
			NSArray* components = [row componentsSeparatedByString:@":"];
			if (components.count == 2) {
				NSInteger typeID = [[components objectAtIndex:0] integerValue];
				NSInteger requiredLevel = [[components objectAtIndex:1] integerValue];
				EVECharacterSheetSkill *characterSkill = self.characterSkills[@(typeID)];
				if (characterSkill.level < requiredLevel) {
					EVEDBInvTypeRequiredSkill* skill = [EVEDBInvTypeRequiredSkill invTypeWithTypeID:typeID error:nil];
					skill.requiredLevel = requiredLevel;
					skill.currentLevel = characterSkill.level;
					float sp = [skill skillPointsAtLevel:requiredLevel - 1];
					skill.currentSP = MAX(sp, characterSkill.skillpoints);
					[self.skills addObject:skill];
				}
			}
		}
	}];
}

- (void) clear {
	[self.skills removeAllObjects];
	_trainingTime = 0;
}

#pragma mark NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString:@"entry"]) {
		NSInteger typeID = [[attributeDict valueForKey:@"skillID"] integerValue];
		NSInteger level = [[attributeDict valueForKey:@"level"] integerValue];
		EVEDBInvTypeRequiredSkill* skill = [EVEDBInvTypeRequiredSkill invTypeWithTypeID:typeID error:nil];
		if (skill) {
			skill.requiredLevel = level;
			[self addSkill:skill];
		}
	}
	else if ([elementName isEqualToString:@"plan"]) {
		self.name = [attributeDict valueForKey:@"name"];
	}
}


#pragma mark - Private

- (void) didUpdateCloud:(NSNotification*) notification {
	NSURL* url = [self.objectID URIRepresentation];
	for (NSManagedObjectID* objectID in [notification.userInfo valueForKey:@"updated"]) {
		if ([url isEqual:[objectID URIRepresentation]]) {
			dispatch_async(dispatch_get_main_queue(), ^{
//				[self.managedObjectContext refreshObject:self mergeChanges:YES];
				[self load];
				[[NSNotificationCenter defaultCenter] postNotificationName:NotificationSkillPlanDidImportFromCloud object:self];
			});
			break;
		}
	}
}

@end
