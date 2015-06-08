//
//  main.m
//  NCExpressions
//
//  Created by Artem Shimanski on 22.12.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import <sqlite3.h>

static NSMutableArray *effects;
static NSMutableArray *expressions;
static NSMutableArray *operands;
static NSMutableArray *attributes;
static NSMutableArray *types;
static NSMutableArray *groups;
static NSMutableArray *categories;

static NSString* output;

static int callback(void *pArg, int argc, char **argv, char **azColName){
	NSMutableArray *rows = (__bridge NSMutableArray*) pArg;
	NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
	for (int i = 0; i < argc; i++) {
		if (argv[i] && azColName[i]) {
			NSString *value = [[NSString alloc] initWithCString:argv[i] encoding:NSUTF8StringEncoding];
			NSString *key = [[NSString alloc] initWithCString:azColName[i] encoding:NSUTF8StringEncoding];
			[dic setValue:value
				   forKey:key];
		}
	}
	[rows addObject:dic];
	
	return SQLITE_OK;
}

static NSMutableDictionary *expressionWithIndex(NSNumber *index) {
	if (!index || [index integerValue] == 0)
		return nil;
	return [[[expressions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"expressionID=%@", index]] lastObject] mutableCopy];
}

static NSMutableDictionary *operandWithIndex(NSNumber *index) {
	if (!index || [index integerValue] == 0)
		return nil;
	return [[[operands filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"operandID=%@", index]] lastObject] mutableCopy];
}

static NSMutableDictionary *attributeWithIndex(NSNumber *index) {
	if (!index || [index integerValue] == 0)
		return nil;
	return [[[attributes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"attributeID=%@", index]] lastObject] mutableCopy];
}

static NSMutableDictionary *typeWithIndex(NSNumber *index) {
	if (!index || [index integerValue] == 0)
		return nil;
	return [[[types filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"typeID=%@", index]] lastObject] mutableCopy];
}

static NSMutableDictionary *groupWithIndex(NSNumber *index) {
	if (!index || [index integerValue] == 0)
		return nil;
	return [[[groups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"groupID=%@", index]] lastObject] mutableCopy];
}

static NSString *getAttribute(NSNumber *attributeID) {
	NSMutableDictionary *dictionary = attributeWithIndex(attributeID);
	return [dictionary valueForKey:@"attributeName"];
}

static NSString *getType(NSNumber *typeID) {
	NSMutableDictionary *dictionary = typeWithIndex(typeID);
	NSString* typeName = [dictionary valueForKey:@"typeName"];
	return typeName ? typeName : @"NULL";
}

static NSString *getGroup(NSNumber *groupID) {
	NSMutableDictionary *dictionary = groupWithIndex(groupID);
	return [dictionary valueForKey:@"groupName"];
}

static NSDictionary *getOperand(NSNumber *operandID) {
	NSMutableDictionary *dictionary = operandWithIndex(operandID);
	if (!dictionary)
		return nil;
	return dictionary;
}

static NSDictionary *getExpression(NSNumber *expressionID) {
	NSMutableDictionary *dictionary = expressionWithIndex(expressionID);
	if (!dictionary)
		return nil;
	[dictionary setValue:getExpression([dictionary valueForKey:@"arg1"]) forKey:@"arg1"];
	[dictionary setValue:getExpression([dictionary valueForKey:@"arg2"]) forKey:@"arg2"];
	[dictionary setValue:getOperand([dictionary valueForKey:@"operandID"]) forKey:@"operand"];
	[dictionary setValue:nil forKey:@"operandID"];
	[dictionary setValue:getAttribute([dictionary valueForKey:@"expressionAttributeID"]) forKey:@"attribute"];
	[dictionary setValue:nil forKey:@"expressionAttributeID"];
	[dictionary setValue:getGroup([dictionary valueForKey:@"expressionGroupID"]) forKey:@"group"];
	[dictionary setValue:nil forKey:@"expressionGroupID"];
	[dictionary setValue:getType([dictionary valueForKey:@"expressionTypeID"]) forKey:@"type"];
	[dictionary setValue:nil forKey:@"expressionTypeID"];
	return dictionary;
}

static void processEffect(NSMutableDictionary *effect) {
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	[dic setValue:effect forKey:@"effect"];
	[effect setValue:getExpression([effect valueForKey:@"preExpression"]) forKey:@"preExpression"];
	[effect setValue:getExpression([effect valueForKey:@"postExpression"]) forKey:@"postExpression"];
	
	for (NSString *key in [NSArray arrayWithObjects:@"effectID", @"effectCategory", @"description", @"guid", @"iconID", @"isOffensive", @"isAssistance", @"durationAttributeID", @"trackingSpeedAttributeID", @"dischargeAttributeID", @"rangeAttributeID", @"falloffAttributeID", @"disallowAutoRepeat", @"published", @"displayName", @"isWarpSafe", @"rangeChance", @"electronicChance", @"propulsionChance", @"distribution", @"sfxName", @"npcUsageChanceAttributeID", @"npcActivationChanceAttributeID", @"fittingUsageChanceAttributeID", nil])
		[effect setValue:nil forKey:key];
	NSData* data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
	[data writeToFile:[NSString stringWithFormat:@"%@/%@.json", output, [effect valueForKey:@"effectName"]] atomically:YES];
}

NSError* exec(sqlite3* db, NSString* sqlRequest, void (^resultBlock)(sqlite3_stmt* stmt, BOOL* needsMore)) {
	sqlite3_stmt* stmt = NULL;
	int result = sqlite3_prepare_v2(db, [sqlRequest cStringUsingEncoding:NSUTF8StringEncoding], (int) [sqlRequest lengthOfBytesUsingEncoding:NSUTF8StringEncoding], &stmt, NULL);
	
	if (!stmt) {
		const char* text = sqlite3_errmsg(db);
		NSString* description = text ? [NSString stringWithCString:text encoding:NSUTF8StringEncoding] : nil;
		NSError* error = [NSError errorWithDomain:0 code:result userInfo:description ? @{NSLocalizedDescriptionKey : description} : nil];
		return error;
	}
	
	BOOL needsMore = YES;
	int n = 0;
	while (sqlite3_step(stmt) == SQLITE_ROW && needsMore) {
		n++;
		resultBlock(stmt, &needsMore);
	}
	
	sqlite3_finalize(stmt);
	return nil;
}

int main (int argc, const char * argv[])
{
	
	@autoreleasepool {
		if (argc == 3) {
			effects = [NSMutableArray array];
			expressions = [NSMutableArray array];
			operands = [NSMutableArray array];
			attributes = [NSMutableArray array];
			types = [NSMutableArray array];
			groups = [NSMutableArray array];
			categories = [NSMutableArray array];
			output = [NSString stringWithUTF8String:argv[2]];
			
			//const char* expression = @"((CurrentShip->medSlots).(ModAdd)).AddItemModifier (medSlots)";
			
			
			
			sqlite3 *pDB;
			pDB = NULL;
			sqlite3_open(argv[1], &pDB);
			
			char *errmsg = NULL;
			sqlite3_exec(pDB, "select * from dgmEffects", callback, (__bridge void*) effects, &errmsg);
			sqlite3_exec(pDB, "select * from dgmOperands", callback, (__bridge void*) operands, &errmsg);
			sqlite3_exec(pDB, "select * from dgmExpressions", callback, (__bridge void*) expressions, &errmsg);
			sqlite3_exec(pDB, "select * from dgmAttributeTypes", callback, (__bridge void*) attributes, &errmsg);
			sqlite3_exec(pDB, "select * from invTypes", callback, (__bridge void*) types, &errmsg);
			sqlite3_exec(pDB, "select * from invGroups", callback, (__bridge void*) groups, &errmsg);
			sqlite3_exec(pDB, "select * from invCategories", callback, (__bridge void*) categories, &errmsg);
			sqlite3_close(pDB);
			
			for (NSMutableDictionary *effect in effects) {
				@autoreleasepool {
					processEffect(effect);
				}
			}
		}
	}
	return 0;
}

