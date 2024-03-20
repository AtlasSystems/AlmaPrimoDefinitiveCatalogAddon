require("Utility");

local settings = {};
settings.AutoSearch = GetSetting("AutoSearch");
settings.AvailableSearchTypes = Utility.StringSplit(",", GetSetting("AvailableSearchTypes"));
settings.SearchPriorityList = Utility.StringSplit(",", GetSetting("SearchPriorityList"));
settings.HomeUrl = GetSetting("HomeURL");
settings.CatalogUrl = GetSetting("CatalogURL");
settings.AutoRetrieveItems = GetSetting("AutoRetrieveItems");
settings.RemoveTrailingSpecialCharacters = GetSetting("RemoveTrailingSpecialCharacters");
settings.AlmaApiUrl = GetSetting("AlmaAPIURL");
settings.AlmaApiKey = GetSetting("AlmaAPIKey");
settings.PrimoSiteCode = GetSetting("PrimoSiteCode");
settings.IdSuffix = GetSetting("IdSuffix");

local interfaceMngr = nil;

-- The catalogSearchForm table allows us to store all objects related to the specific form inside the table so that we can easily
-- prevent naming conflicts if we need to add more than one form and track elements from both.
local catalogSearchForm = {};
catalogSearchForm.Form = nil;
catalogSearchForm.Browser = nil;
catalogSearchForm.RibbonPage = nil;
catalogSearchForm.ItemsButton = nil;
catalogSearchForm.ImportButtons = {};
catalogSearchForm.SearchButtons = {};

local mmsIdsCache = {};
local holdingsXmlDocCache = {};
local itemsXmlDocCache = {};

luanet.load_assembly("System");
luanet.load_assembly("System.Data");
luanet.load_assembly("System.Drawing");
luanet.load_assembly("System.Xml");
luanet.load_assembly("System.Windows.Forms");
luanet.load_assembly("DevExpress.XtraBars");
luanet.load_assembly("log4net");

local types = {};
types["System.Data.DataTable"] = luanet.import_type("System.Data.DataTable");
types["System.Drawing.Size"] = luanet.import_type("System.Drawing.Size");
types["DevExpress.XtraBars.BarShortcut"] = luanet.import_type("DevExpress.XtraBars.BarShortcut");
types["System.Windows.Forms.Shortcut"] = luanet.import_type("System.Windows.Forms.Shortcut");
types["System.Windows.Forms.Keys"] = luanet.import_type("System.Windows.Forms.Keys");
types["System.Windows.Forms.Cursor"] = luanet.import_type("System.Windows.Forms.Cursor");
types["System.Windows.Forms.Cursors"] = luanet.import_type("System.Windows.Forms.Cursors");
types["System.DBNull"] = luanet.import_type("System.DBNull");
types["System.Windows.Forms.Application"] = luanet.import_type("System.Windows.Forms.Application");
types["System.Xml.XmlDocument"] = luanet.import_type("System.Xml.XmlDocument");
types["log4net.LogManager"] = luanet.import_type("log4net.LogManager");
types["System.Timers.Timer"] = luanet.import_type("System.Timers.Timer");

local rootLogger = "AtlasSystems.Addons.AlmaPrimoDefinitiveCatalogSearch";
local log = types["log4net.LogManager"].GetLogger(rootLogger);

local product = types["System.Windows.Forms.Application"].ProductName;
local cursor = types["System.Windows.Forms.Cursor"];
local cursors = types["System.Windows.Forms.Cursors"];
local watcherEnabled = false;
local pageWatcherTimer = nil;
local recordsLastRetrievedFrom = "";
local layoutMode = "browse";
local browserType = nil;
if AddonInfo.Browsers and AddonInfo.Browsers.WebView2 then
    browserType = "WebView2";
else
    browserType = "Chromium";
end

function Init()
    interfaceMngr = GetInterfaceManager();

    -- Create a form
    catalogSearchForm.Form = interfaceMngr:CreateForm(DataMapping.LabelName, DataMapping.LabelName);
    log:DebugFormat("catalogSearchForm.Form = {0}", catalogSearchForm.Form);

    -- Add a browser
    catalogSearchForm.Browser = catalogSearchForm.Form:CreateBrowser(DataMapping.LabelName, "Catalog Search Browser", DataMapping.LabelName, browserType);

    -- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method.  We can retrieve that one and add our buttons to it.
    catalogSearchForm.RibbonPage = catalogSearchForm.Form:GetRibbonPage(DataMapping.LabelName);

    -- Create the search button(s)
    catalogSearchForm.SearchButtons["Home"] = catalogSearchForm.RibbonPage:CreateButton("New Search", GetClientImage(DataMapping.Icons[product]["Web"]), "ShowCatalogHome", "Search Options");

    log:Info("Creating buttons for available search types.");
    local success, err = pcall(function()
        for _, searchType in ipairs(settings.AvailableSearchTypes) do
            local searchStyle = DataMapping.SearchTypes[searchType].SearchStyle;

            log:DebugFormat("Creating button for search type {0} with search style {1}", searchType, searchStyle);

            catalogSearchForm.SearchButtons[searchType] = catalogSearchForm.RibbonPage:CreateButton(DataMapping.SearchTypes[searchType].ButtonText, GetClientImage(DataMapping.SearchTypes[searchType][product .. "Icon"]), "Placeholder", "Search Options");

            catalogSearchForm.SearchButtons[searchType].BarButton:add_ItemClick(ButtonSearch);
            catalogSearchForm.SearchButtons[searchType].BarButton.Tag = {SearchType = searchType, SearchStyle = searchStyle};
        end
    end);
    if not success then
        log:ErrorFormat("{0}. Search types may be configured incorrectly. Please ensure SearchTypes exist in DataMapping.lua for each search type in the AvailableSearchTypes setting.", TraverseError(err));
        interfaceMngr:ShowMessage("Search types may be configured incorrectly. Please ensure SearchTypes exist in DataMapping.lua for each search type in the AvailableSearchTypes setting. See client log for details.", "Configuration Error");
    end

    log:Info("Creating buttons for import profiles.");
    for importProfileName, importProfile in pairs(DataMapping.ImportProfiles) do
        if importProfile.Product == product then
            log:DebugFormat("Creating button for import profile {0}", importProfileName);

            catalogSearchForm.ImportButtons[importProfileName] = catalogSearchForm.RibbonPage:CreateButton(DataMapping.ImportProfiles[importProfileName].ButtonText, GetClientImage(DataMapping.ImportProfiles[importProfileName].Icon), "Placeholder", "Process");

            catalogSearchForm.ImportButtons[importProfileName].BarButton:add_ItemClick(DoItemImport);
            catalogSearchForm.ImportButtons[importProfileName].BarButton.Tag = {ImportProfileName = importProfileName};
            catalogSearchForm.ImportButtons[importProfileName].BarButton.Enabled = false;
        end
    end

    if (not settings.AutoRetrieveItems) then
        catalogSearchForm.ItemsButton = catalogSearchForm.RibbonPage:CreateButton("Retrieve Items", GetClientImage(DataMapping.Icons[product]["Retrieve Items"]), "RetrieveItems", "Process");
        catalogSearchForm.ItemsButton.BarButton.ItemShortcut = types["DevExpress.XtraBars.BarShortcut"](types["System.Windows.Forms.Shortcut"].CtrlR);
        catalogSearchForm.ItemsButton.BarButton.Enabled = false;
    end

    BuildItemsGrid();
    catalogSearchForm.Form:LoadLayout("CatalogLayout_Browse_" .. browserType .. ".xml");

    -- After we add all of our buttons and form elements, we can show the form.
    catalogSearchForm.Form:Show();

    -- Initializing the AlmaApi
    AlmaApi.ApiUrl = settings.AlmaApiUrl;
    AlmaApi.ApiKey = settings.AlmaApiKey;

    -- Search when opened if autoSearch is true
    local fieldtype = GetFieldType();
    local identifier = GetFieldValue(DataMapping.SourceFields[product]["Identifier"].Table, DataMapping.SourceFields[product]["Identifier"][fieldtype]);

	OnFormClosing:RegisterFormClosingEvent(interfaceMngr, StopRecordPageWatcher);

    if settings.AutoSearch and identifier and identifier > 0 then
        log:Debug("Performing AutoSearch");

        PerformSearch({nil, nil});
    else
        log:Debug("Navigating to Catalog URL because AutoSearch is disabled.");
        ShowCatalogHome();
    end
end

function StopRecordPageWatcher()
    if watcherEnabled then
        log:Debug("Stopping record page watcher.");
        pageWatcherTimer:Stop();
		pageWatcherTimer:Dispose();

        watcherEnabled = false;
    end
end

function StartRecordPageWatcher()
    if not watcherEnabled then
        log:Debug("Starting record page watcher.");

        pageWatcherTimer = types["System.Timers.Timer"](3000);
        -- This ensures the pagetWatcherTimer's Elapsed event is raised on the browser's UI thread,
        -- which is necessary to be able to change layouts and display the grid.
        pageWatcherTimer.SynchronizingObject = catalogSearchForm.Browser.WebBrowser;

		pageWatcherTimer:add_Elapsed(IsRecordPageLoaded);
		pageWatcherTimer:Start();

        watcherEnabled = true;
    end
end

function ShowCatalogHome()
    if layoutMode == "import" then
        layoutMode = "browse";
        catalogSearchForm.Form:LoadLayout("CatalogLayout_Browse_" .. browserType .. ".xml");
    end
    StartRecordPageWatcher();
    catalogSearchForm.Browser:Navigate(settings.HomeUrl);
end

-- Search Functions
function Placeholder()
    -- Does nothing. This is a placeholder assigned as the function handler when creating the search buttons since a null cannot be used.
    -- We are assigning a custom ItemClick event instead that passes event args to ButtonSearch.
end

function ButtonSearch(sender, args)
    local searchType = args.Item.Tag.SearchType;
    local searchStyle = args.Item.Tag.SearchStyle;

    log:InfoFormat("{0} search button clicked.", searchType);

    PerformSearch({searchType, searchStyle});
end

function GetAutoSearchInfo()
    local priorityList = settings.SearchPriorityList;

    log:Info("Determining autosearch type from search priority list.");
    local fieldType = GetFieldType();
    for _, searchType in ipairs(priorityList) do
        if DataMapping.SearchTypes[searchType] and DataMapping.SearchTypes[searchType][product .. "SourceField"] ~= nil then
            
            local fieldDefinition = DataMapping.SearchTypes[searchType][product .. "SourceField"];
            local fieldValue = GetFieldValue(fieldDefinition.Table, fieldDefinition[fieldType]);

            log:DebugFormat("Search type: {0}, field value: {1}", searchType, fieldValue);
            if fieldValue and fieldValue ~= "" then
                return {searchType, DataMapping.SearchTypes[searchType]["SearchStyle"]};
            end
        end
    end

    return {nil, nil};
end

-- searchInfo is a Lua table where index 1 = searchType and index 2 = searchStyle
function PerformSearch(searchInfo)
    if layoutMode == "import" then
        layoutMode = "browse";
        catalogSearchForm.Form:LoadLayout("CatalogLayout_Browse_" .. browserType .. ".xml");
    end
    StartRecordPageWatcher();

    if searchInfo[1] == nil then
        searchInfo = GetAutoSearchInfo();
        log:DebugFormat("Autosearch type: {0}", searchInfo[1]);
        if not searchInfo[1] then
            log:Debug("The search type could not be determined using the current request information.");
            return;
        end
    end

    local fieldDefinition = DataMapping.SearchTypes[searchInfo[1]][product .. "SourceField"];

    local fieldType = GetFieldType();
    local searchTerm = GetFieldValue(fieldDefinition.Table, fieldDefinition[fieldType]);

    if not searchTerm or searchTerm == "" then
        log:Info("No value found in " .. product .. " field '" .. fieldDefinition[fieldType] .. ".' Search will not be performed.");
        return;
    end

    local searchUrl = "";
    local encodedSiteCode = Utility.URLEncode(settings.PrimoSiteCode):gsub("%%", "%%%%");
    local encodedSearchType = Utility.URLEncode(DataMapping.SearchTypes[searchInfo[1]]["PrimoField"]):gsub("%%", "%%%%");
    local encodedSearchTerm = Utility.URLEncode(searchTerm):gsub("%%", "%%%%");

    --Construct the search url based on the base catalog url and search style.
    searchUrl = settings.CatalogUrl .. DataMapping.SearchStyleUrls[searchInfo[2]]
    :gsub("{PrimoSiteCode}", encodedSiteCode)
    :gsub("{SearchType}", encodedSearchType)
    :gsub("{SearchTerm}", encodedSearchTerm);
    
    log:InfoFormat("Navigating to {0}", searchUrl);
    catalogSearchForm.Browser:Navigate(searchUrl);
end

function GetMmsIds()
    log:DebugFormat("Retrieving IDs from {0}", catalogSearchForm.Browser.Address);

    local itemDetails = catalogSearchForm.Browser:EvaluateScript([[document.getElementById("item-details").innerText;]]).Result;
    local ids = {};
    if itemDetails then
        ids = ExtractIds(itemDetails);
    else
        log:Debug("Element with ID 'item-details' not found.");
    end

    if #ids > 0 then
        StopRecordPageWatcher();
        local mmsIds = ConvertIeIdsToMmsIds(ids);
        if #mmsIds > 0 then
            cursor.Current = cursors.Default;

            log:InfoFormat("Found {0} MMS IDs.", #mmsIds);
            return mmsIds;
        end
    end

    cursor.Current = cursors.Default;
    return {};
end

function ExtractIds(itemDetails)
    local idMatches = {};
    local urlId = (catalogSearchForm.Browser.Address):match("%d+" .. settings.IdSuffix);
    -- Easy way to prevent duplicates regardless of order since the keys get overwritten.
    -- In rare cases the URL won't contain an ID.
    if urlId then
        idMatches[urlId] = true;
    end

    -- MMS Ids (and presumably IE IDs) all have the same last four digits specific to the institution.
    -- 99 is the prefix for MMS IDs, and IE IDs always have 1, 2, or 5 as their first digit and 1 as the second digit.

    log:Info("Extracting IDs from item-details element.");
    for id in itemDetails:gmatch("%d+" .. settings.IdSuffix) do
        if id:find("^99") or id:find("^[125]1") then
            log:DebugFormat("Found ID: {0}", id);
            idMatches[id] = true;
        end
    end
    
    local ids = {};
    for id, _ in pairs(idMatches) do
        ids[#ids+1] = id;
    end

    for i = 1, #ids do
        log:Debug(ids[i]);
    end
    return ids;
end

function ConvertIeIdsToMmsIds(ieIds)
    local resolvedIds = {};
    local mmsIds = {};

    for i = 1, #ieIds do
        if ieIds[i]:find("^[125]1") then
            local bibResponse = AlmaApi.RetrieveBibs(ieIds[i], "ie_id");
            local totalRecordCount = tonumber(bibResponse:SelectSingleNode("//@total_record_count").Value);

            if totalRecordCount and totalRecordCount > 0 then
                local mmsId = bibResponse:SelectSingleNode("bibs/bib/mms_id").InnerXml;
                log:DebugFormat("MMS ID: {0}", mmsId);
                if mmsId then
                    log:DebugFormat("IE ID {0} -> MMS ID {1}", ieIds[i], mmsId);
                    -- We want to avoid duplicates here as well.
                    resolvedIds[mmsId] = true;
                end
            end
        else
            -- Already an MMS ID.
            resolvedIds[ieIds[i]] = true;
        end
    end

    for id, _ in pairs(resolvedIds) do
        mmsIds[#mmsIds+1] = id;
    end

    return mmsIds;
end

function IsRecordPageLoaded()
    local pageUrl = catalogSearchForm.Browser.Address;
    local itemDetailsScript = [[(function(){
        var itemDetailsElement = document.getElementById("item-details");
        if (itemDetailsElement != null){
            return "True";
        }
        return "False";
    })();]];

    local itemDetails = catalogSearchForm.Browser:EvaluateScript(itemDetailsScript).Result == "True";

    if pageUrl:find("fulldisplay%?") and itemDetails then
        log:DebugFormat("Is a record page. {0}", pageUrl);
        ToggleItemsUIElements(true);
    else
        log:DebugFormat("Is not a record page. {0}", pageUrl);
        ToggleItemsUIElements(false);
    end
end

function Truncate(value, size)
    if size == nil then
        log:Debug("Size was nil. Truncating to 50 characters");
        size = 50;
    end
    if ((value == nil) or (value == "")) then
        log:Debug("Value was nil or empty. Skipping truncation.");
        return value;
    else
        log:DebugFormat("Truncating to {0} characters: {1}", size, value);
        return string.sub(value, 0, size);
    end
end

function ImportField(targetTable, targetField, newFieldValue, targetSize)
    if newFieldValue and newFieldValue ~= "" and newFieldValue ~= types["System.DBNull"].Value then
        SetFieldValue(targetTable, targetField, Truncate(newFieldValue, targetSize));
    end
end

function ToggleItemsUIElements(enabled)
    if (enabled) then
        log:Debug("Enabling UI.");
        
        if (settings.AutoRetrieveItems) then
            -- Prevents the addon from rerunning RetrieveItems on the same page
            if (catalogSearchForm.Browser.Address ~= recordsLastRetrievedFrom) then
                -- Sets the recordsLastRetrievedFrom to the current page
                local hasRecords = RetrieveItems();
                recordsLastRetrievedFrom = catalogSearchForm.Browser.Address;
                catalogSearchForm.Grid.GridControl.Enabled = hasRecords;
            end
        else
            catalogSearchForm.ItemsButton.BarButton.Enabled = true;
            recordsLastRetrievedFrom = "";
            -- If there's an item in the Item Grid
            if(catalogSearchForm.Grid.GridControl.MainView.FocusedRowHandle > -1) then
                catalogSearchForm.Grid.GridControl.Enabled = true;
                for buttonName, _ in pairs(catalogSearchForm.ImportButtons) do
                    catalogSearchForm.ImportButtons[buttonName].BarButton.Enabled = true;
                end
            end
        end
    else
        log:Debug("Disabling UI.");
        ClearItems();
        recordsLastRetrievedFrom = "";
        catalogSearchForm.Grid.GridControl.Enabled = false;
        for buttonName, _ in pairs(catalogSearchForm.ImportButtons) do
            catalogSearchForm.ImportButtons[buttonName].BarButton.Enabled = false;
        end

        if (not settings.AutoRetrieveItems) then
            catalogSearchForm.ItemsButton.BarButton.Enabled = false;
        end

        if layoutMode == "import" then
            layoutMode = "browse";
            catalogSearchForm.Form:LoadLayout("CatalogLayout_Browse_" .. browserType .. ".xml");
        end
    end
    log:Debug("Finished Toggling UI Elements");
end

function BuildItemsGrid()
    catalogSearchForm.Grid = catalogSearchForm.Form:CreateGrid("CatalogItemsGrid", "Items");
    catalogSearchForm.Grid.GridControl.Enabled = false;

    catalogSearchForm.Grid.TextSize = types["System.Drawing.Size"].Empty;
    catalogSearchForm.Grid.TextVisible = false;

    local gridControl = catalogSearchForm.Grid.GridControl;

    -- Set the grid view options
    local gridView = gridControl.MainView;
    gridView.OptionsView.ShowIndicator = false;
    gridView.OptionsView.ShowGroupPanel = false;
    gridView.OptionsView.RowAutoHeight = true;
    gridView.OptionsView.ColumnAutoWidth = true;
    gridView.OptionsBehavior.AutoExpandAllGroups = true;
    gridView.OptionsBehavior.Editable = false;

    gridControl:BeginUpdate();

    -- Item Grid Column Settings
    local gridColumn;
    gridColumn = gridView.Columns:Add();
    gridColumn.Caption = "MMS ID";
    gridColumn.FieldName = "ReferenceNumber";
    gridColumn.Name = "gridColumnReferenceNumber";
    gridColumn.Visible = false;
    gridColumn.OptionsColumn.ReadOnly = true;
    gridColumn.Width = 50;

    gridColumn = gridView.Columns:Add();
    gridColumn.Caption = "Holding ID";
    gridColumn.FieldName = "HoldingId";
    gridColumn.Name = "gridColumnHoldingId";
    gridColumn.Visible = false;
    gridColumn.OptionsColumn.ReadOnly = true;
    gridColumn.Width = 50;

    gridColumn = gridView.Columns:Add();
    gridColumn.Caption = "Location";
    gridColumn.FieldName = "Location";
    gridColumn.Name = "gridColumnLocation";
    gridColumn.Visible = true;
    gridColumn.VisibleIndex = 0;
    gridColumn.OptionsColumn.ReadOnly = true;

    gridColumn = gridView.Columns:Add();
    gridColumn.Caption = "Barcode";
    gridColumn.FieldName = "Barcode";
    gridColumn.Name = "gridColumnBarcode";
    gridColumn.Visible = true;
    gridColumn.VisibleIndex = 0;
    gridColumn.OptionsColumn.ReadOnly = true;

    gridColumn = gridView.Columns:Add();
    gridColumn.Caption = "Location Code";
    gridColumn.FieldName = "Library";
    gridColumn.Name = "gridColumnLibrary";
    gridColumn.Visible = true;
    gridColumn.OptionsColumn.ReadOnly = true;

    gridColumn = gridView.Columns:Add();
    gridColumn.Caption = "Call Number";
    gridColumn.FieldName = "CallNumber";
    gridColumn.Name = "gridColumnCallNumber";
    gridColumn.Visible = true;
    gridColumn.VisibleIndex = 1;
    gridColumn.OptionsColumn.ReadOnly = true;

    gridColumn = gridView.Columns:Add();
    gridColumn.Caption = "Item Description";
    gridColumn.FieldName = "Description";
    gridColumn.Name = "gridColumnDescription";
    gridColumn.Visible = true;
    gridColumn.VisibleIndex = 1;
    gridColumn.OptionsColumn.ReadOnly = true;

    gridControl:EndUpdate();

    gridView:add_FocusedRowChanged(ItemsGridFocusedRowChanged);
end

function ItemsGridFocusedRowChanged(sender, args)
    if (args.FocusedRowHandle > -1) then
        for buttonName, _ in pairs(catalogSearchForm.ImportButtons) do
            catalogSearchForm.ImportButtons[buttonName].BarButton.Enabled = true;
        end
        catalogSearchForm.Grid.GridControl.Enabled = true;
    else
        for buttonName, _ in pairs(catalogSearchForm.ImportButtons) do
            catalogSearchForm.ImportButtons[buttonName].BarButton.Enabled = false;
        end
    end;
end

function RetrieveItems()
    cursor.Current = cursors.WaitCursor;
    if layoutMode == "browse" then
        layoutMode = "import";
        catalogSearchForm.Form:LoadLayout("CatalogLayout_Import_" .. browserType .. ".xml");
    end

    local pageUrl = catalogSearchForm.Browser.Address;
    local mmsIds = {};
    
    if not mmsIdsCache[pageUrl] then
        mmsIdsCache[pageUrl] = GetMmsIds();
    end
    mmsIds = mmsIdsCache[pageUrl];

    if #mmsIds > 0 then
        local hasHoldings = false;
        -- Create a new Item Data Table to Populate
        local itemsDataTable = CreateItemsTable();
        for i = 1, #mmsIds do
            -- Cache the response if it hasn't been cached
            if (holdingsXmlDocCache[mmsIds[i]] == nil) then
                log:DebugFormat("Caching Holdings For {0}", mmsIds[i]);
                holdingsXmlDocCache[mmsIds[i]] = AlmaApi.RetrieveHoldingsList(mmsIds[i]);
            end

            local holdingsResponse = holdingsXmlDocCache[mmsIds[i]];

            -- Check if it has any holdings available
            local totalHoldingCount = tonumber(holdingsResponse:SelectSingleNode("holdings/@total_record_count").Value);
            local suppressedNodeList = holdingsResponse:SelectNodes("holdings/holding/suppress_from_publishing[text()='true']");
            local suppressedHoldingsCount = tonumber(suppressedNodeList.Count);

            log:DebugFormat("Records available: {0} ({1} total, {2} suppressed)", totalHoldingCount - suppressedHoldingsCount, totalHoldingCount, suppressedHoldingsCount);

            -- Retrieve Item Data if Holdings are available
            if totalHoldingCount - suppressedHoldingsCount > 0 then
                hasHoldings = true;
                -- Get list of the holding ids
                local holdingIds = GetHoldingIds(holdingsResponse);

                for _, holdingId in ipairs(holdingIds) do
                    log:DebugFormat("Holding ID: {0}", holdingId);
                    -- Cache the response if it hasn't been cached
                    if (itemsXmlDocCache[holdingId] == nil ) then
                        log:DebugFormat("Caching items for {0}", mmsIds[i]);
                        itemsXmlDocCache[holdingId] = AlmaApi.RetrieveItemsList(mmsIds[i], holdingId);
                    end

                    local itemsResponse = itemsXmlDocCache[holdingId];

                    PopulateItemsDataSources(itemsResponse, itemsDataTable);
                end
            end
        end

        if not hasHoldings then
            ClearItems();
        end
        cursor.Current = cursors.Default;
        return hasHoldings;
    else
        return false;
    end
end

function CreateItemsTable()
    local itemsTable = types["System.Data.DataTable"]();

    itemsTable.Columns:Add("ReferenceNumber");
    itemsTable.Columns:Add("Barcode");
    itemsTable.Columns:Add("HoldingId");
    itemsTable.Columns:Add("Library");
    itemsTable.Columns:Add("Location");
    itemsTable.Columns:Add("CallNumber");
    itemsTable.Columns:Add("Description");

    return itemsTable;
end

function ClearItems()
    catalogSearchForm.Grid.GridControl:BeginUpdate();
    catalogSearchForm.Grid.GridControl.DataSource = CreateItemsTable();
    catalogSearchForm.Grid.GridControl:EndUpdate();
end

function GetHoldingIds(holdingsXmlDoc)
    local holdingNodes = holdingsXmlDoc:GetElementsByTagName("holding");
    local holdingIds = {};
    log:DebugFormat("Holding nodes found: {0}", holdingNodes.Count);

    for i = 0, holdingNodes.Count - 1 do
        local holdingNode = holdingNodes:Item(i);
        table.insert(holdingIds, holdingNode["holding_id"].InnerXml);
    end

    return holdingIds;
end

function SetItemNodeFromCustomizedMapping(itemRow, itemNode, aeonField, mappings)
    if itemNode then
        if mappings[itemNode.InnerXml] and mappings[itemNode.InnerXml] ~= "" then
            itemRow = SetItemNode(itemRow, mappings[itemNode.InnerXml], aeonField);
        else
            log:DebugFormat("Customized mapping NOT found for {0}. Setting row to innerXml.", aeonField, itemNode.InnerXml);
            itemRow = SetItemNode(itemRow, itemNode.InnerXml, aeonField);
        end
        return itemRow;
    else
        log:DebugFormat("Cannot set {0}. Item node is Nil", aeonField);
        return itemRow;
    end
end

function SetItemNodeFromXML(itemRow, itemNode, aeonField)
    if itemNode then
        return SetItemNode(itemRow, itemNode.InnerXml, aeonField);
    else
        log:DebugFormat("Cannot set {0}. Item Node is Nil", aeonField);
        return itemRow;
    end
end

function SetItemNode(itemRow, data, aeonField)
    local success, error = pcall(function()
        itemRow:set_Item(aeonField, data);
    end);

    if success then
        log:DebugFormat("Setting {0} to {1}", aeonField, data);
    else
        log:DebugFormat("Error setting {0} to {1}", aeonField, data);
        log:ErrorFormat("Error: {0}", error);
    end

    return itemRow;
end

function PopulateItemsDataSources( response, itemsDataTable )
    catalogSearchForm.Grid.GridControl:BeginUpdate();

    local itemNodes = response:GetElementsByTagName("item");
    log:DebugFormat("Item nodes found: {0}", itemNodes.Count);

    for i = 0, itemNodes.Count - 1 do
        local itemRow = itemsDataTable:NewRow();
        local itemNode = itemNodes:Item(i);

        local bibData = itemNode["bib_data"];
        local holdingData = itemNode["holding_data"];
        local itemData = itemNode["item_data"];
        log:DebugFormat("ItemNode: {0}", itemNode.OuterXml);

        itemRow = SetItemNodeFromXML(itemRow, bibData["mms_id"], "ReferenceNumber");
        itemRow = SetItemNodeFromXML(itemRow, holdingData["holding_id"], "HoldingId");
        itemRow = SetItemNodeFromXML(itemRow, holdingData["call_number"], "CallNumber");
        itemRow = SetItemNodeFromCustomizedMapping(itemRow, itemData["location"], "Location", CustomizedMapping.Locations);
        itemRow = SetItemNodeFromXML(itemRow, itemData["library"], "Library");
        itemRow = SetItemNodeFromXML(itemRow, itemData["barcode"], "Barcode");
        itemRow = SetItemNodeFromXML(itemRow, itemData["description"], "Description");

        itemsDataTable.Rows:Add(itemRow);
    end
        
    catalogSearchForm.Grid.GridControl.DataSource = itemsDataTable;
    catalogSearchForm.Grid.GridControl:EndUpdate();
end

function DoItemImport(sender, args)
    cursor.Current = cursors.WaitCursor;

    local importProfileName = args.Item.Tag.ImportProfileName;

    log:Debug("Retrieving import row.");
    local importRow = catalogSearchForm.Grid.GridControl.MainView:GetFocusedRow();

    if (importRow == nil) then
        log:Debug("Import row was nil. Cancelling the import.");
        return;
    end;

    log:Info("Importing item values.");

    local fieldType = GetFieldType();
    local itemSuccess, itemErr = pcall(function()
        for _, target in ipairs(DataMapping.ImportFields.Item[importProfileName]) do
            local importValue = importRow:get_Item(target.Value);

            log:DebugFormat("Importing value '{0}' to {1}", importValue, target[fieldType]);

            if not target[fieldType] or target[fieldType] == "" then
                error(fieldType .. " cannot be null or an empty string.");
            end

            ImportField(target.Table, target[fieldType], importValue, target.MaxSize);
        end
    end);
    if not itemSuccess then
        log:ErrorFormat("{0}. Import profile may not be configured correctly. Please ensure that the import profile in DataMapping.lua corresponds to a set of item import fields and that each is a valid " .. product .. " field.", TraverseError(itemErr));
        interfaceMngr:ShowMessage("Import profile may not be configured correctly. Please ensure that the import profile in DataMapping.lua corresponds to a set of item import fields and that each is a valid " .. product .. " field. See client log for details.", "Configuration Error");
    end

    local mmsId = importRow:get_Item("ReferenceNumber");
    local holdingId = importRow:get_Item("HoldingId");

    log:Info("Importing bib values.");
    local bibSuccess, bibErr = pcall(function()

        local bibliographicInformation = GetMarcInformation(importProfileName, mmsId);
        for _, target in ipairs(bibliographicInformation) do

            ImportField(target.Table, target.Field, target.Value, target.MaxSize);
        end
    end);

    if not bibSuccess then
        log:ErrorFormat("{0}. Import profile may not be configured correctly. Please ensure that the import profile in DataMapping.lua corresponds to a set of bibliographic import fields and that each is a valid " .. product .. " field.", TraverseError(bibErr));
        interfaceMngr:ShowMessage("Import profile may not be configured correctly. Please ensure that the import profile in DataMapping.lua corresponds to a set of bibliographic import fields and that each is a valid " .. product .. " field. See client log for details.", "Configuration Error");
    end

    log:Info("Importing holding values.");
    local holdingSuccess, holdingErr = pcall(function()

        local holdingInformation = GetMarcInformation(importProfileName, mmsId, holdingId);
        for _, target in ipairs(holdingInformation) do

            log:DebugFormat("Importing value '{0}' to {1}", target.Value, target[fieldType]);
            ImportField(target.Table, target.Field, target.Value, target.MaxSize);
        end
    end);
    if not holdingSuccess then
        log:ErrorFormat("{0}. Import profile may not be configured correctly. Please ensure that the import profile in DataMapping.lua corresponds to a set of holding import fields and that each is a valid " .. product .. " field.", TraverseError(holdingErr));
        interfaceMngr:ShowMessage("Import profile may not be configured correctly. Please ensure that the import profile in DataMapping.lua corresponds to a set of holding import fields and that each is a valid " .. product .. " field. See client log for details.", "Configuration Error");
    end

    cursor.Current = cursors.Default;
    if product == "Ares" then
        ExecuteCommand("SwitchTab", {"Details"});
    else
        ExecuteCommand("SwitchTab", "Detail");
    end
end

function GetMarcInformation(importProfileName, mmsId, holdingId)
    local marcInformation = {};

    local marcXmlDoc = nil;
    if holdingId then
        log:DebugFormat("Retrieving MARC info for holding ID {0}", holdingId);
        marcXmlDoc = AlmaApi.RetrieveHoldingsRecordInfo(mmsId, holdingId);
    else
        log:DebugFormat("Retrieving MARC info for MMS ID {0}", mmsId);
        marcXmlDoc = AlmaApi.RetrieveBibs(mmsId, "mms_id");
    end

    local recordNodes = marcXmlDoc:SelectNodes("//record");

    if recordNodes then
        log:InfoFormat("Found {0} MARC records", recordNodes.Count);

        -- Loops through each record
        for recordNodeIndex = 0, (recordNodes.Count - 1) do
            log:DebugFormat("Processing record {0}", recordNodeIndex);
            local recordNode = recordNodes:Item(recordNodeIndex);

            -- Loops through each import mapping
            local mappingTable = {};
            if holdingId then
                mappingTable = DataMapping.ImportFields.Holding[importProfileName];
            else
                mappingTable = DataMapping.ImportFields.Bibliographic[importProfileName];
            end

            local fieldType = GetFieldType();
            for _, target in ipairs(mappingTable) do
                if target then
                    if not target[fieldType] or target[fieldType] == "" then
                        error(fieldType .. " cannot be null or an empty string");
                    end

                    log:DebugFormat("XPath =: {0}", target.Value);
                    log:DebugFormat("Target: {0}", target.Field);
                    local datafieldNode = recordNode:SelectNodes(target.Value);
                    log:DebugFormat("DataField Node Match Count: {0}", datafieldNode.Count);

                    if (datafieldNode.Count > 0) then
                        local fieldValue = "";

                        -- Loops through each data field node retured from xPath and concatenates them (generally only 1)
                        for datafieldNodeIndex = 0, (datafieldNode.Count - 1) do
                            log:DebugFormat("datafieldnode value is: {0}", datafieldNode:Item(datafieldNodeIndex).InnerText);
                            fieldValue = fieldValue .. " " .. datafieldNode:Item(datafieldNodeIndex).InnerText;
                        end

                        log:DebugFormat("target.Field: {0}", target.Field);
                        log:DebugFormat("target.MaxSize: {0}", target.MaxSize);

                        if(settings.RemoveTrailingSpecialCharacters) then
                            fieldValue = Utility.RemoveTrailingSpecialCharacters(fieldValue);
                        else
                            fieldValue = Utility.Trim(fieldValue);
                        end

                        AddMarcInformation(marcInformation, target.Table, target.Field, fieldValue, target.MaxSize);
                    end
                end
            end
        end
    end

    return marcInformation;
end

function AddMarcInformation(marcInformation, targetTable, targetField, fieldValue, targetMaxSize)
    local marcInfoEntry = {Table = targetTable, Field = targetField, Value = fieldValue, MaxSize = targetMaxSize}
    table.insert( marcInformation, marcInfoEntry );
end

function GetFieldType()
    local fieldtype = "Field";
    if product == "ILLiad" then
        fieldtype = GetFieldValue("Transaction", "RequestType") .. "Field";
    end

    return fieldtype;
end

function OnError(err)
    log:ErrorFormat("Alma Primo Definitive Catalog Search encountered an error: {0}", TraverseError(err));
end

function TraverseError(e)
    if not e.GetType then
        -- Not a .NET type
        return e;
    else
        if not e.Message then
            -- Not a .NET exception
            return e;
        end
    end

    log:Debug(e.Message);

    if e.InnerException then
        return TraverseError(e.InnerException);
    else
        return e.Message;
    end
end