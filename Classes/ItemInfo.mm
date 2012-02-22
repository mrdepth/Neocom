//
//  ItemInfo.mm
//  EVEUniverse
//
//  Created by Mr. Depth on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ItemInfo.h"

@interface ItemInfo(Private)

- (void) clear;

@end

class ItemInfoContext : public eufe::Item::Context
{
public:
	ItemInfoContext(ItemInfo* itemInfo) : itemInfo_([itemInfo retain]) {}
	
	virtual ~ItemInfoContext()
	{
		[itemInfo_ clear];
		[itemInfo_ release];
	}
	
	ItemInfo* getItemInfo() {return itemInfo_;}
private:
	ItemInfo* itemInfo_;
};

@implementation ItemInfo

+ (id) itemInfoWithItem:(boost::shared_ptr<eufe::Item>) aItem error:(NSError **)errorPtr {
	boost::shared_ptr<eufe::Item::Context> context = aItem->getContext();
	if (context == NULL)
	{
		ItemInfo* itemInfo = [[[ItemInfo alloc] initWithItem:aItem error:errorPtr] autorelease];
		ItemInfoContext* context = new ItemInfoContext(itemInfo);
		aItem->setContext(boost::shared_ptr<eufe::Item::Context>(context));
		return itemInfo;
	}
	else
		return dynamic_cast<ItemInfoContext*>(context.get())->getItemInfo();
}

- (id) initWithItem:(boost::shared_ptr<eufe::Item>) aItem error:(NSError **)errorPtr {
	if (self = [super initWithTypeID:aItem->getTypeID() error:errorPtr]) {
		item = boost::weak_ptr<eufe::Item>(aItem);
	}
	return self;
}

- (boost::shared_ptr<eufe::Item>) item {
	return item.lock();
}

@end

@implementation ItemInfo(Private)

- (void) clear {
	item.reset();
}

@end