DataMapping = {}
DataMapping.Icons = {};
DataMapping.SearchTypes = {};
DataMapping.SearchStyleUrls = {};
DataMapping.SourceFields = {};
DataMapping.ImportProfiles = {};
DataMapping.ImportFields = {};
DataMapping.ImportFields.Bibliographic = {};
DataMapping.ImportFields.Holding = {};
DataMapping.ImportFields.Item = {};
DataMapping.ImportFields.StaticHolding = {};

-- The display name for the addon's tab.
DataMapping.LabelName = "Catalog Search";

-- Icons for non-search buttons for Aeon. 
    -- Icons can also be added for ILLiad or Ares by using those product names as keys.
DataMapping.Icons["Aeon"] = {};
DataMapping.Icons["Aeon"]["Home"] = "home_32x32";
DataMapping.Icons["Aeon"]["Web"] = "web_32x32";
DataMapping.Icons["Aeon"]["Retrieve Items"] = "record_32x32";

--[[ 
    SearchTypes
    - ButtonText: The text that appears on the ribbon button for the search.
    - PrimoField: The field name used by Primo in the seach URL. 
    - SearchStyle: Query or Browse. 
    - AeonIcon: The name of the icon file to use as the button's image.
        Icons for ILLiad and Ares can be used by adding an "ILLiadIcon" or "AresIcon" property.
    - AeonSourceField: The table and field name to draw the search term from in the request.
        Source fields for ILLiad and Ares can be used by adding an ILLiadSourceField or AresSourceField property.
--]]
DataMapping.SearchTypes["Title"] = {
    ButtonText = "Title",
    PrimoField = "title",
    SearchStyle = "Query",
    AeonIcon = "srch_32x32",
    AeonSourceField = { Table = "Transaction", Field = "ItemTitle" }
};
DataMapping.SearchTypes["Author"] = {
    ButtonText = "Author",
    PrimoField = "creator",
    SearchStyle = "Query",
    AeonIcon = "srch_32x32",
    AeonSourceField = { Table = "Transaction", Field = "ItemAuthor" }
};
DataMapping.SearchTypes["Call Number"] = {
    ButtonText = "Call Number",
    PrimoField = "lsr01",
    SearchStyle = "Query",
    AeonIcon = "srch_32x32",
    AeonSourceField = { Table = "Transaction", Field = "CallNumber" }
};
DataMapping.SearchTypes["ISBN"] = {
    ButtonText = "ISBN",
    PrimoField = "isbn",
    SearchStyle = "Query",
    AeonIcon = "srch_32x32",
    AeonSourceField = { Table = "Transaction", Field = "ItemISxN" }
};
DataMapping.SearchTypes["ISSN"] = {
    ButtonText = "ISSN",
    PrimoField = "issn",
    SearchStyle = "Query",
    AeonIcon = "srch_32x32",
    AeonSourceField = { Table = "Transaction", Field = "ItemISxN" }
};
-- Catalog Number uses the Any search type because Primo catalogs don't have built in MMS ID searching.
DataMapping.SearchTypes["Catalog Number"] = {
    ButtonText = "Catalog Number",
    PrimoField = "any",
    SearchStyle = "Query",
    AeonIcon = "srch_32x32",
    AeonSourceField = { Table = "Transaction", Field = "ReferenceNumber" }
};

-- SearchStyleUrls
-- Words in brackets will be replaced by their corresponding settings or values by the addon.
-- Only one Query and one Browse style URL may be defined. These will be concatenated to the
    -- end of the CatalogUrl setting when searching.
DataMapping.SearchStyleUrls["Query"] = "search?vid={PrimoSiteCode}&query={SearchType},contains,{SearchTerm},AND&tab=books&search_scope=default_scope&mode=advanced";
DataMapping.SearchStyleUrls["Browse"] = "browse?vid={PrimoSiteCode}&browseQuery={SearchTerm}&browseScope={SearchType}&innerPnxIndex=-1&numOfUsedTerms=-1&fn=BrowseSearch";

-- Source Fields: Aeon
-- Only necessary for source fields not associated with a SearchType. To define source fields used in searches, 
    -- add a SourceField property prefixed with the product name to the SearchType.
DataMapping.SourceFields["Aeon"] = {};
DataMapping.SourceFields["Aeon"]["TransactionNumber"] = { Table = "Transaction", Field = "TransactionNumber" };

--[[
Import Profiles
Each import profile defines a set of fields to be imported. A button will be generated for each
profile with a Product property matching the product you're using. The key for the import profile
must have a corresponding set of import fields with matching keys in the next section.
    - ButtonText: The text that appears on the ribbon button for the import.
    - Product: The product the import profile is for.
    - Icon: The name of the icon file to use as the button's image.
--]]

DataMapping.ImportProfiles["Default"] = {
    ButtonText = "Import",
    Product = "Aeon",
    Icon = "impt_32x32"
}

-- Import Fields: The table for each ImportFields section must be defined for each import profile above.
    -- running the addon to work properly, even if it is empty. Example of an empty ImportFields table:
        -- DataMapping.ImportFields.Bibliographic["Default"] = { };

--[[ 
    Bib-level import fields.
    - Table and Field determine which request field the value will be imported to.
    - The character limit (MaxSize) for a field can be found at https://support.atlas-sys.com/hc/en-us/articles/360011920013-Aeon-Database-Tables
        for Aeon, https://support.atlas-sys.com/hc/en-us/articles/360011812074-ILLiad-Database-Tables for ILLiad,
        and https://support.atlas-sys.com/hc/en-us/articles/360011923233-Ares-Database-Tables for Ares. The character limit is
        in parentheses next to the field type.
    - Value must be an XPath expression.
    --]]
DataMapping.ImportFields.Bibliographic["Default"] = {
    {
        Table = "Transaction",
        Field = "ItemTitle", MaxSize = 255,
        Value = "//datafield[@tag='245']/subfield[@code='a']|//datafield[@tag='245']/subfield[@code='b']"
    },
    {
        Table = "Transaction",
        Field = "ItemAuthor", MaxSize = 255,
        Value = "//datafield[@tag='100' or @tag='110' or @tag='111']/subfield[@code='a' or @code='b']"
    },
    {
        Table = "Transaction",
        Field ="ItemDate", MaxSize = 50,
        Value = "//datafield[@tag='260']/subfield[@code='c']|//datafield[@tag='264']/subfield[@code='c']"
    },
    {
        Table = "Transaction",
        Field ="ItemEdition", MaxSize = 50,
        Value = "//datafield[@tag='300']"
    },
    {
-- notes and boundwith information 
        Table = "Transaction",
        Field ="ItemSubTitle", MaxSize = 255,
        Value = "//datafield[@tag='990']|//datafield[@tag='992']|//datafield[@tag='993']"
    },
    {
-- Volume/box - shirea 5/2021
        Table = "Transaction",
        Field ="ItemVolume", MaxSize = 255,
        Value = "//datafield[@tag='988']/subfield[@code='p']|//datafield[@tag='988']/subfield[@code='b']"
    },
    {
-- Series - shirea 5/2021
        Table = "Transaction.CustomFields",
        Field ="SeriesNumber", MaxSize = 255,
        Value = "//datafield[@tag='830']"
    },
-- OCLC Number
    {
        Table = "Transaction.CustomFields",
        Field = "OCLCNum", MaxSize = 255,
        Value = "//datafield[@tag='035'][subfield[text()[contains(.,'(OCoLC)')]]][1]"
    },
-- DSpace URL
    {
        Table = "Transaction.CustomFields",
        Field = "DspaceURL", MaxSize = 255,
        Value = "//datafield[@tag='856'][subfield[text()[contains(.,'DSpace@MIT')]]]/subfield[@code='u']"
    }
};

-- Holding-level import fields. Value must be an XPath expression.
DataMapping.ImportFields.Holding["Default"] = {

}

-- Item-level import fields. Value should not be changed.
DataMapping.ImportFields.Item["Default"] = {
    {
        Table = "Transaction",
        Field = "ReferenceNumber", MaxSize = 50,
        Value = "ReferenceNumber"
    },
    {
        Table = "Transaction",
        Field = "CallNumber", MaxSize = 255,
        Value = "CallNumber"
    },
    {
        Table = "Transaction",
        Field = "ItemNumber", MaxSize = 255,
        Value = "Barcode"
    },
    {
        Table = "Transaction",
        Field = "Location", MaxSize = 255,
        Value = "Location"
    },
    {
        Table = "Transaction",
        Field = "ItemIssue", MaxSize = 255,
        Value = "Description"
    }
};