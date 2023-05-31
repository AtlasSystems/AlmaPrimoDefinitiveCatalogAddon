WebClient = {};

local types = {};
types["log4net.LogManager"] = luanet.import_type("log4net.LogManager");
types["System.Net.WebClient"] = luanet.import_type("System.Net.WebClient");
types["System.Text.Encoding"] = luanet.import_type("System.Text.Encoding");
types["System.Xml.XmlTextReader"] = luanet.import_type("System.Xml.XmlTextReader");
types["System.Xml.XmlDocument"] = luanet.import_type("System.Xml.XmlDocument");

-- Create a logger
local log = types["log4net.LogManager"].GetLogger(rootLogger .. ".AlmaApi");

local function GetRequest(requestUrl, headers)
    local webClient = types["System.Net.WebClient"]();
    local response = nil;
    webClient.Encoding = types["System.Text.Encoding"].UTF8;

    for _, header in ipairs(headers) do
        webClient.Headers:Add(header);
    end
    
    log:DebugFormat("Request URL: {0}", requestUrl);
    local success, error = pcall(function ()
        response = webClient:DownloadString(requestUrl);
    end);

    webClient:Dispose();

    if(success) then
        return response;
    else
        log:ErrorFormat("Unable to get response from the request url: {0}", error);
    end
end

local function ReadResponse( responseString )
    if (responseString and #responseString > 0) then

        local responseDocument = types["System.Xml.XmlDocument"]();

        local documentLoaded, error = pcall(function ()
            responseDocument:LoadXml(responseString);
        end);

        if (documentLoaded) then
            return responseDocument;
        else
            log:WarnFormat("Unable to load response content as XML: {0}", error);
            return nil;
        end
    else
        log:Warn("Unable to read response content.");
    end

    return nil;
end

--Exports
WebClient.GetRequest = GetRequest;
WebClient.ReadResponse = ReadResponse;
