//
//  main.m
//  EVENPCBuilder
//
//  Created by Артем Шиманский on 27.01.14.
//  Copyright (c) 2014 Артем Шиманский. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"

int parse(NSMutableArray* rows, NSArray* groups, int parentGroupID) {
	int groupID = parentGroupID + 1;
	for (NSDictionary* group in groups) {
		NSString* s = [NSString stringWithFormat:@"INSERT INTO npcGroup VALUES(%d, %@, \"%@\", %@, %@);",
					   groupID,
					   parentGroupID ? @(parentGroupID): @"NULL",
					   group[@"groupName"],
					   group[@"iconName"] ? [NSString stringWithFormat:@"\"%@\"", group[@"iconName"]] : @"NULL",
					   group[@"groupID"] ? group[@"groupID"] : @"NULL"];
		[rows addObject:s];
		groupID = parse(rows, group[@"groups"], groupID);
	}
	return groupID;
}

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		NSArray* npc = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:@"/Users/admin/Work/git/Neocom/dbTools/EVENPCBuilder/npc.json"]
													   options:0
														 error:nil];
		NSMutableArray* rows = [NSMutableArray new];
		[rows addObject:@"DROP TABLE IF EXISTS npcGroup;\n\
CREATE TABLE \"npcGroup\" (\n\
\"npcGroupID\" INTEGER NOT NULL,\n\
\"parentNpcGroupID\" INTEGER DEFAULT NULL,\n\
\"npcGroupName\" TEXT,\n\
\"iconName\" TEXT NULL,\n\
\"groupID\" INTEGER DEFAULT NULL,\n\
PRIMARY KEY (\"npcGroupID\")\n\
);\n"];
		parse(rows, npc, 0);
		[[rows componentsJoinedByString:@"\n"] writeToFile:@"/Users/admin/Work/git/Neocom/dbTools/EVENPCBuilder/npc.sql"
												atomically:YES
												  encoding:NSUTF8StringEncoding
													 error:nil];
	}
    return 0;
}

