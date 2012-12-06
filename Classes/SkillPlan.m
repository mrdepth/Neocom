//
//  SkillPlan.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SkillPlan.h"
#import "TrainingQueue.h"
#import "EVEAccount.h"
#import "Globals.h"

@implementation SkillPlan
@synthesize skills;
@synthesize characterAttributes;
@synthesize characterSkills;
@synthesize characterID;
@synthesize name;

+ (id) skillPlanWithAccount:(EVEAccount*) aAccount {
	return [[[SkillPlan alloc] initWithAccount:aAccount] autorelease];
}

+ (id) skillPlanWithAccount:(EVEAccount*) aAccount eveMonSkillPlanPath:(NSString*) skillPlanPath {
	return [[[SkillPlan alloc] initWithAccount:aAccount eveMonSkillPlanPath:skillPlanPath] autorelease];
}

+ (id) skillPlanWithAccount:(EVEAccount*) aAccount eveMonSkillPlan:(NSString*) skillPlan {
	return [[[SkillPlan alloc] initWithAccount:aAccount eveMonSkillPlan:skillPlan] autorelease];
}

- (id) initWithAccount:(EVEAccount*) aAccount {
	if (self = [super init]) {
		if (!aAccount) {
			[self release];
			return nil;
		}
		self.skills = [NSMutableArray array];
		trainingTime = -1;

		self.characterAttributes = [aAccount characterAttributes];
		self.characterSkills = aAccount.characterSheet.skillsMap;
		self.characterID = aAccount.characterID;
	}
	return self;
}

- (id) init {
	if (self = [super init]) {
		self.skills = [NSMutableArray array];
		trainingTime = -1;
		characterID = 0;
		self.characterAttributes = [CharacterAttributes defaultCharacterAttributes];
	}
	return self;
}

- (id) initWithAccount:(EVEAccount*) aAccount eveMonSkillPlanPath:(NSString*) skillPlanPath {
	if (self = [self initWithAccount:aAccount]) {
		NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL fileURLWithPath:skillPlanPath]];
		parser.delegate = self;
		[parser parse];
		[parser release];
	}
	return self;
}

- (id) initWithAccount:(EVEAccount*) aAccount eveMonSkillPlan:(NSString*) skillPlan {
	if (self = [self initWithAccount:aAccount]) {
		NSXMLParser* parser = [[NSXMLParser alloc] initWithData:[skillPlan dataUsingEncoding:NSUTF8StringEncoding]];
		parser.delegate = self;
		if (![parser parse]) {
			[parser release];
			[self release];
			return nil;
		}
		[parser release];
	}
	return self;
}

- (void) dealloc {
	[skills release];
	[characterAttributes retain];
	[characterSkills retain];
	[name release];
	[super dealloc];
}

- (void) addSkill:(EVEDBInvTypeRequiredSkill*) skill {
	EVECharacterSheetSkill *characterSkill = [characterSkills valueForKey:[NSString stringWithFormat:@"%d", skill.typeID]];
	if (characterSkill.level >= skill.requiredLevel)
		return;
	
	BOOL addedDependence = NO;
	for (NSInteger level = characterSkill.level + 1; level <= skill.requiredLevel; level++) {
		BOOL isExist = NO;
		for (EVEDBInvTypeRequiredSkill *item in skills) {
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
			float sp = [requiredSkill skillpointsAtLevel:level - 1];
			requiredSkill.currentSP = MAX(sp, characterSkill.skillpoints);
			[skills addObject:requiredSkill];
			[[NSNotificationCenter defaultCenter] postNotificationName:NotificationSkillPlanDidAddSkill object:self userInfo:[NSDictionary dictionaryWithObject:requiredSkill forKey:@"skill"]];
		}
	}
	trainingTime = -1;
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
	for (EVEDBInvTypeRequiredSkill* requiredSkill in [NSArray arrayWithArray:skills]) {
		if (requiredSkill.typeID == typeID && requiredSkill.requiredLevel >= level) {
			trainingTime -= (requiredSkill.requiredSP - requiredSkill.currentSP) / [characterAttributes skillpointsPerSecondForSkill:requiredSkill];
			//[skills removeObject:requiredSkill];
			[indexes addIndex:index];
			//[[NSNotificationCenter defaultCenter] postNotificationName:NotificationSkillPlanDidRemoveSkill object:self userInfo:@{@"skill" : requiredSkill, @"index" : @(index)}];
		}
		index++;
	}
	[skills removeObjectsAtIndexes:indexes];
	if (indexes.count > 0)
		[[NSNotificationCenter defaultCenter] postNotificationName:NotificationSkillPlanDidRemoveSkill object:self userInfo:@{@"indexes" : indexes}];
}

- (NSTimeInterval) trainingTime {
	if (trainingTime < 0) {
		trainingTime = 0;
		
		for (EVEDBInvTypeRequiredSkill *skill in skills) {
			if (skill.currentLevel < skill.requiredLevel)
				trainingTime += (skill.requiredSP - skill.currentSP) / [characterAttributes skillpointsPerSecondForSkill:skill];
		}
	}
	return trainingTime;
}

- (void) reload {
	
}

- (void) resetTrainingTime {
	trainingTime = -1;
}

- (void) save {
	if (!characterID)
		return;
	NSMutableArray* items = [[NSMutableArray alloc] init];
	for (EVEDBInvTypeRequiredSkill* skill in skills) {
		[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInt:skill.typeID], @"typeID",
						  [NSNumber numberWithInt:skill.requiredLevel], @"level", nil]];
	}
	NSString* path = [[Globals documentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"skillPlan_%d.plist", characterID]];
	[items writeToURL:[NSURL fileURLWithPath:path] atomically:YES];
	[items release];
}

- (void) load {
	[skills removeAllObjects];
	NSString* path = [[Globals documentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"skillPlan_%d.plist", characterID]];
	NSArray* items = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:path]];
	
	for (NSDictionary* item in items) {
		NSInteger typeID = [[item valueForKey:@"typeID"] integerValue];
		NSInteger requiredLevel = [[item valueForKey:@"level"] integerValue];
		EVECharacterSheetSkill *characterSkill = [characterSkills valueForKey:[NSString stringWithFormat:@"%d", typeID]];
		if (characterSkill.level < requiredLevel) {
			/*for (NSInteger level = characterSkill.level + 1; level <= requiredLevel; level++) {
				BOOL found = NO;
				for (EVEDBInvTypeRequiredSkill* skill in skills) {
					if (skill.typeID == typeID && skill.requiredLevel == level) {
						found = YES;
						break;
					}
				}
				if (!found) {
					EVEDBInvTypeRequiredSkill* skill = [EVEDBInvTypeRequiredSkill invTypeWithTypeID:typeID error:nil];
					skill.requiredLevel = level;
					skill.currentLevel = characterSkill.level;
					float sp = [skill skillpointsAtLevel:level - 1];
					skill.currentSP = MAX(sp, characterSkill.skillpoints);
					//skill.currentSP = characterSkill.skillpoints;
					[skills addObject:skill];
				}
			}*/
/*			EVEDBInvTypeRequiredSkill* skill = [EVEDBInvTypeRequiredSkill invTypeWithTypeID:typeID error:nil];
			skill.requiredLevel = requiredLevel;
			skill.currentLevel = characterSkill.level;
			skill.currentSP = characterSkill.skillpoints;
			[skills addObject:skill];*/
			EVEDBInvTypeRequiredSkill* skill = [EVEDBInvTypeRequiredSkill invTypeWithTypeID:typeID error:nil];
			skill.requiredLevel = requiredLevel;
			skill.currentLevel = characterSkill.level;
			float sp = [skill skillpointsAtLevel:requiredLevel - 1];
			skill.currentSP = MAX(sp, characterSkill.skillpoints);
			[skills addObject:skill];
		}
	}
}

- (void) clear {
	[skills removeAllObjects];
	trainingTime = 0;
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

@end
