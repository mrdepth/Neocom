update  invMarketGroups set marketGroupName=(select text from trnTranslations where tcID=36 and languageID="EN-US" AND keyID = marketGroupID) where marketGroupName = "" or marketGroupName is null;
delete from invMarketGroups where hasTypes = 1 and (select count(*) from invTypes as b where b.marketGroupID=invMarketGroups.marketGroupID) = 0;
delete from invMarketGroups where hasTypes = 0 and (select count(*) from invMarketGroups as b where b.parentGroupID=invMarketGroups.marketGroupID) = 0;
delete from invMarketGroups where hasTypes = 0 and (select count(*) from invMarketGroups as b where b.parentGroupID=invMarketGroups.marketGroupID) = 0;
