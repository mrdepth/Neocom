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

static NSMutableDictionary *effects;
static NSMutableDictionary *expressions;
static NSMutableDictionary *operands;
static NSMutableDictionary *attributes;
static NSMutableDictionary *types;
static NSMutableDictionary *groups;
static NSMutableDictionary *categories;

static NSString* output;

static int callback(void *pArg, int argc, char **argv, char **azColName){
	NSDictionary *arg = (__bridge NSDictionary*) pArg;
	NSString* pKey = arg[@"pKey"];
	NSMutableDictionary* rows = arg[@"rows"];
	
	NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
	NSString* key;
	for (int i = 0; i < argc; i++) {
		if (argv[i] && azColName[i]) {
			NSString *value = [[NSString alloc] initWithCString:argv[i] encoding:NSUTF8StringEncoding];
			NSString *k = [[NSString alloc] initWithCString:azColName[i] encoding:NSUTF8StringEncoding];
			[dic setValue:value
				   forKey:k];
			if ([k isEqualToString:pKey])
				key = value;
		}
	}
	rows[key] = dic;
	
	return SQLITE_OK;
}

static NSMutableDictionary *expressionWithIndex(NSNumber *index) {
	if (!index || [index integerValue] == 0)
		return nil;
	return [expressions[index] mutableCopy];
	//return [[[expressions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"expressionID=%@", index]] lastObject] mutableCopy];
}

static NSMutableDictionary *operandWithIndex(NSNumber *index) {
	if (!index || [index integerValue] == 0)
		return nil;
	return [operands[index] mutableCopy];
	//return [[[operands filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"operandID=%@", index]] lastObject] mutableCopy];
}

static NSMutableDictionary *attributeWithIndex(NSNumber *index) {
	if (!index || [index integerValue] == 0)
		return nil;
	return [attributes[index] mutableCopy];
	//return [[[attributes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"attributeID=%@", index]] lastObject] mutableCopy];
}

static NSMutableDictionary *typeWithIndex(NSNumber *index) {
	if (!index || [index integerValue] == 0)
		return nil;
	return [types[index] mutableCopy];
	//return [[[types filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"typeID=%@", index]] lastObject] mutableCopy];
}

static NSMutableDictionary *groupWithIndex(NSNumber *index) {
	if (!index || [index integerValue] == 0)
		return nil;
	return [groups[index] mutableCopy];
	//return [[[groups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"groupID=%@", index]] lastObject] mutableCopy];
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
			effects = [NSMutableDictionary new];
			expressions = [NSMutableDictionary new];
			operands = [NSMutableDictionary new];
			attributes = [NSMutableDictionary new];
			types = [NSMutableDictionary new];
			groups = [NSMutableDictionary new];
			categories = [NSMutableDictionary new];
			output = [NSString stringWithUTF8String:argv[2]];
			[[NSFileManager defaultManager] createDirectoryAtPath:output withIntermediateDirectories:YES attributes:nil error:nil];
			
			
			//const char* expression = @"((CurrentShip->medSlots).(ModAdd)).AddItemModifier (medSlots)";
			
			
			
			sqlite3 *pDB;
			pDB = NULL;
			sqlite3_open(argv[1], &pDB);
			
			char *errmsg = NULL;
			sqlite3_exec(pDB, "select * from dgmEffects", callback, (__bridge void*) @{@"rows":effects, @"pKey":@"effectID"}, &errmsg);
			sqlite3_exec(pDB, "select * from dgmOperands", callback, (__bridge void*) @{@"rows":operands, @"pKey":@"operandID"}, &errmsg);
			sqlite3_exec(pDB, "select * from dgmExpressions", callback, (__bridge void*) @{@"rows":expressions, @"pKey":@"expressionID"}, &errmsg);
			sqlite3_exec(pDB, "select * from dgmAttributeTypes", callback, (__bridge void*) @{@"rows":attributes, @"pKey":@"attributeID"}, &errmsg);
			sqlite3_exec(pDB, "select * from invTypes", callback, (__bridge void*) @{@"rows":types, @"pKey":@"typeID"}, &errmsg);
			sqlite3_exec(pDB, "select * from invGroups", callback, (__bridge void*) @{@"rows":groups, @"pKey":@"groupID"}, &errmsg);
			sqlite3_exec(pDB, "select * from invCategories", callback, (__bridge void*) @{@"rows":categories, @"pKey":@"categoryID"}, &errmsg);
			sqlite3_close(pDB);
			
			[effects enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
				@autoreleasepool {
					processEffect(obj);
				}
			}];
		}
	}
	return 0;
}

