local AlmaApiInternal = {};
AlmaApiInternal.ApiUrl = nil;
AlmaApiInternal.ApiKey = nil;


local types = {};
types["log4net.LogManager"] = luanet.import_type("log4net.LogManager");
types["System.Net.WebClient"] = luanet.import_type("System.Net.WebClient");
types["System.Text.Encoding"] = luanet.import_type("System.Text.Encoding");
types["System.Xml.XmlTextReader"] = luanet.import_type("System.Xml.XmlTextReader");
types["System.Xml.XmlDocument"] = luanet.import_type("System.Xml.XmlDocument");

-- Create a logger
local log = types["log4net.LogManager"].GetLogger(rootLogger .. ".AlmaApi");

AlmaApi = AlmaApiInternal;

local function RetrieveHoldingsList( mmsId )
    local requestUrl = AlmaApiInternal.ApiUrl .."bibs/"..
        Utility.URLEncode(mmsId) .."/holdings?apikey=" .. Utility.URLEncode(AlmaApiInternal.ApiKey);
    local headers = {"Accept: application/xml", "Content-Type: application/xml"};
    log:DebugFormat("Request URL: {0}", requestUrl);
    local response = WebClient.GetRequest(requestUrl, headers);

    return WebClient.ReadResponse(response);
end

-- idType is either "mms_id" or "ie_id"
local function RetrieveBibs(id, idType)
    local requestUrl = AlmaApiInternal.ApiUrl .. "bibs?apikey="..
        Utility.URLEncode(AlmaApiInternal.ApiKey) .. "&" .. idType .. "=" .. Utility.URLEncode(id);
    local headers = {"Accept: application/xml", "Content-Type: application/xml"};
    log:DebugFormat("Request URL: {0}", requestUrl);

    local response = WebClient.GetRequest(requestUrl, headers);

    return WebClient.ReadResponse(response);
end

local function RetrieveItemsSublist(mmsId, holdingId, offset )
    local requestUrl = AlmaApiInternal.ApiUrl .."bibs/" ..
        Utility.URLEncode(mmsId) .."/holdings/" .. Utility.URLEncode(holdingId) .. "/items?limit=100&offset=" .. tostring(offset) .. "&apikey=" ..
        Utility.URLEncode(AlmaApiInternal.ApiKey);

    local headers = {"Accept: application/xml", "Content-Type: application/xml"};

    log:DebugFormat("Request URL: {0}", requestUrl);
    local response = WebClient.GetRequest(requestUrl, headers);
	
    return WebClient.ReadResponse(response);
end

local function RetrieveItemsList(mmsId, holdingId)
	local xmlResult, itemsNode;
	local offset, totalItems = 0, 0;
	
	repeat
		local xmlSubresult = RetrieveItemsSublist(mmsId, holdingId, offset);
		
		if (xmlResult == nil) then
			xmlResult = xmlSubresult;
			itemsNode = xmlResult:SelectSingleNode("/items");
			totalItems = tonumber(itemsNode:SelectSingleNode("@total_record_count").Value);
			log:DebugFormat("Holding contains {0} items", totalItems);
		else
			--Merge the next subset results with the working list
			local itemNodes = xmlSubresult:SelectNodes("/items/item");
			
			for i = 0, itemNodes.Count - 1 do
				local nodeCopy = xmlResult:ImportNode(itemNodes:Item(i), true); 
				itemsNode:AppendChild(nodeCopy);
			end
		end
		
		offset = offset + 100;
	
	until totalItems <= offset;

	return xmlResult;
end

local function RetrieveHoldingsRecordInfo(mmsId, holdingId)
    local requestUrl = AlmaApiInternal.ApiUrl .."bibs/" ..
        Utility.URLEncode(mmsId) .."/holdings/" .. Utility.URLEncode(holdingId) .. "/?apikey=" ..
        Utility.URLEncode(AlmaApiInternal.ApiKey);

    local headers = {"Accept: application/xml", "Content-Type: application/xml"};

    log:DebugFormat("Request URL: {0}", requestUrl);
    local response = WebClient.GetRequest(requestUrl, headers);
    
    return WebClient.ReadResponse(response);
end

-- Exports
AlmaApi.RetrieveHoldingsList = RetrieveHoldingsList;
AlmaApi.RetrieveBibs = RetrieveBibs;
AlmaApi.RetrieveItemsList = RetrieveItemsList;
AlmaApi.RetrieveHoldingsRecordInfo = RetrieveHoldingsRecordInfo;