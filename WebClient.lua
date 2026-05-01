WebClient = {};

local apiKey = nil;

local types = {};
types["log4net.LogManager"] = luanet.import_type("log4net.LogManager");
types["System.Net.WebClient"] = luanet.import_type("System.Net.WebClient");
types["System.Text.Encoding"] = luanet.import_type("System.Text.Encoding");
types["System.Xml.XmlTextReader"] = luanet.import_type("System.Xml.XmlTextReader");
types["System.Xml.XmlDocument"] = luanet.import_type("System.Xml.XmlDocument");
types["System.IO.StreamReader"] = luanet.import_type("System.IO.StreamReader");

-- Create a logger
local log = types["log4net.LogManager"].GetLogger(rootLogger .. ".AlmaApi");

local function Initialize(key)
    apiKey = key;
end

local function Redact(value)
    if value == nil or apiKey == nil or apiKey == "" then
        return value;
    end
    -- Escape any pattern-special characters so the API key is treated literally.
    local literalPattern = apiKey:gsub("(%W)", "%%%1");
    -- gsub returns the replacement count as a second value; the parens drop it.
    return (tostring(value):gsub(literalPattern, "[REDACTED]"));
end

local function GetWebExceptionMessage(exception)
    local message = "";

    if exception and exception.Message then
        message = exception.Message;
        if (exception.InnerException) then
            message = message .. "\r\n" .. GetWebExceptionMessage(exception.InnerException);

            if exception.InnerException.Response and exception.InnerException.Response ~= "Response" then
                -- This is necessary to get the response body from exceptions thrown by WebClients.
                local streamReader = types["System.IO.StreamReader"](exception.InnerException.Response:GetResponseStream());
                local responseContent = streamReader:ReadToEnd();
                log:DebugFormat("Web exception response: {0}", Redact(responseContent));
            end
        end
    elseif exception then
        message = exception;
    end

    return message;
end

local function GetRequest(requestUrl, headers)
    local webClient = types["System.Net.WebClient"]();
    local response = nil;
    webClient.Encoding = types["System.Text.Encoding"].UTF8;

    for _, header in ipairs(headers) do
        webClient.Headers:Add(header);
    end

    log:DebugFormat("Request URL: {0}", Redact(requestUrl));
    local success, error = pcall(function ()
        response = webClient:DownloadString(requestUrl);
    end);

    webClient:Dispose();

    if(success) then
        return response;
    else
        log:ErrorFormat("Unable to get response from the request url: {0}", Redact(GetWebExceptionMessage(error)));
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
WebClient.Initialize = Initialize;
WebClient.GetRequest = GetRequest;
WebClient.ReadResponse = ReadResponse;
