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

-- Icons for non-search buttons.
DataMapping.Icons["Aeon"] = {};
DataMapping.Icons["Aeon"]["Home"] = "home_32x32";
DataMapping.Icons["Aeon"]["Web"] = "web_32x32";
DataMapping.Icons["Aeon"]["Retrieve Items"] = "record_32x32";

DataMapping.Icons["ILLiad"] = {};
DataMapping.Icons["ILLiad"]["Home"] = "Home32";
DataMapping.Icons["ILLiad"]["Web"] = "Web32";
DataMapping.Icons["ILLiad"]["Retrieve Items"] = "Record32";

DataMapping.Icons["Ares"] = {};
DataMapping.Icons["Ares"]["Home"] = "Home32";
DataMapping.Icons["Ares"]["Web"] = "Web32";
DataMapping.Icons["Ares"]["Retrieve Items"] = "Record32";

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
    ILLiadIcon = "Search32",
    AresIcon = "Search32",
    AeonSourceField = { Table = "Transaction", Field = "ItemTitle" },
    ILLiadSourceField = { Table = "Transaction", LoanField = "LoanTitle", ArticleField = "PhotoJournalTitle" },
    AresSourceField = { Table = "Item", Field = "Title" }
};
DataMapping.SearchTypes["Author"] = {
    ButtonText = "Author",
    PrimoField = "creator",
    SearchStyle = "Query",
    AeonIcon = "srch_32x32",
    ILLiadIcon = "Search32",
    AresIcon = "Search32",
    AeonSourceField = { Table = "Transaction", Field = "ItemAuthor" },
    ILLiadSourceField = { Table = "Transaction", LoanField = "LoanAuthor", ArticleField = "PhotoItemAuthor" },
    AresSourceField = { Table = "Item", Field = "Author" }
};
DataMapping.SearchTypes["Call Number"] = {
    ButtonText = "Call Number",
    PrimoField = "lsr01",
    SearchStyle = "Query",
    AeonIcon = "srch_32x32",
    ILLiadIcon = "Search32",
    AresIcon = "Search32",
    AeonSourceField = { Table = "Transaction", Field = "CallNumber" },
    ILLiadSourceField = { Table = "Trannsaction", LoanField = "CallNumber", ArticleField = "CallNumber" },
    AresSourceField = { Table = "Item", Field = "Callnumber" }
};
DataMapping.SearchTypes["ISBN"] = {
    ButtonText = "ISBN",
    PrimoField = "isbn",
    SearchStyle = "Query",
    AeonIcon = "srch_32x32",
    ILLiadIcon = "Search32",
    AresIcon = "Search32",
    AeonSourceField = { Table = "Transaction", Field = "ItemISxN" },
    ILLiadSourceField = { Table = "Transaction", LoanField = "ISSN", ArticleField = "ISSN" },
    AresSourceField = { Table = "Item", Field = "ISXN" }
};
DataMapping.SearchTypes["ISSN"] = {
    ButtonText = "ISSN",
    PrimoField = "issn",
    SearchStyle = "Query",
    AeonIcon = "srch_32x32",
    ILLiadIcon = "Search32",
    AresIcon = "Search32",
    AeonSourceField = { Table = "Transaction", Field = "ItemISxN" },
    ILLiadSourceField = { Table = "Transaction", LoanField = "ISSN", ArticleField = "ISSN" },
    AresSourceField = { Table = "Item", Field = "ISXN" }
};
-- Catalog Number uses the Any search type because Primo catalogs don't have built in MMS ID searching.
DataMapping.SearchTypes["Catalog Number"] = {
    ButtonText = "Catalog Number",
    PrimoField = "any",
    SearchStyle = "Query",
    AeonIcon = "srch_32x32",
    ILLiadIcon = "Search32",
    AresIcon = "Search32",
    AeonSourceField = { Table = "Transaction", Field = "ReferenceNumber" },
    ILLiadSourceField = { Table = "Transaction", LoanField = "ReferenceNumber" , ArticleField = "ReferenceNumber" },
    AresSourceField = { Table = "Item", Field = "ReferenceNumber" }
};

-- SearchStyleUrls
-- Words in brackets will be replaced by their corresponding settings or values by the addon.
-- Only one Query and one Browse style URL may be defined. These will be concatenated to the
    -- end of the CatalogUrl setting when searching.
DataMapping.SearchStyleUrls["Query"] = "search?vid={PrimoSiteCode}&query={SearchType},contains,{SearchTerm},AND&tab=books&search_scope=default_scope&mode=advanced";
DataMapping.SearchStyleUrls["Browse"] = "browse?vid={PrimoSiteCode}&browseQuery={SearchTerm}&browseScope={SearchType}&innerPnxIndex=-1&numOfUsedTerms=-1&fn=BrowseSearch";

-- Source Fields: Aeon
-- Only necessary for source fields not associated with a SearchType. To define source fields used in searches, 
    -- add a SourceField property prefixed with the product name to the SearchType. Do not change entries for
    -- Identifier.
DataMapping.SourceFields["Aeon"] = {};
DataMapping.SourceFields["Aeon"]["Identifier"] = { Table = "Transaction", Field = "TransactionNumber" };
DataMapping.SourceFields["ILLiad"] = {};
DataMapping.SourceFields["ILLiad"]["Identifier"] = { Table = "Transaction", LoanField = "TransactionNumber", ArticleField = "TransactionNumber" };
DataMapping.SourceFields["Ares"] = {};
DataMapping.SourceFields["Ares"]["Identifier"] = { Table = "Item", Field = "ItemID" }

--[[
Import Profiles
Each import profile defines a set of fields to be imported. A button will be generated for each
profile with a Product property matching the product you're using. The key for the import profile
must have a corresponding set of import fields with matching keys in the next section.
    - ButtonText: The text that appears on the ribbon button for the import.
    - Product: The product the import profile is for.
    - Icon: The name of the icon file to use as the button's image.
--]]

DataMapping.ImportProfiles["AeonDefault"] = {
    ButtonText = "Import",
    Product = "Aeon",
    Icon = "impt_32x32"
}

DataMapping.ImportProfiles["ILLiadDefault"] = {
    ButtonText = "Import",
    Product = "ILLiad",
    Icon = "Import32"
}

DataMapping.ImportProfiles["AresDefault"] = {
    ButtonText = "Import",
    Product = "Ares",
    Icon = "Import32"
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
DataMapping.ImportFields.Bibliographic["AeonDefault"] = {
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
        Field = "ItemPublisher", MaxSize = 255,
        Value = "//datafield[@tag='260']/subfield[@code='b']"
    },
    {
        Table = "Transaction",
        Field = "ItemPlace", MaxSize = 255,
        Value = "//datafield[@tag='260']/subfield[@code='a']"
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

DataMapping.ImportFields.Bibliographic["ILLiadDefault"] = {
    {
        Table = "Transaction",
        LoanField = "LoanTitle", ArticleField = "PhotoJournalTitle",
        MaxSize = 255,
        Value = "//datafield[@tag='245']/subfield[@code='a']|//datafield[@tag='245']/subfield[@code='b']"
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
DataMapping.ImportFields.Holding["AeonDefault"] = {

};

DataMapping.ImportFields.Holding["ILLiadDefault"] = {

};

DataMapping.ImportFields.Holding["AresDefault"] = {

};

-- Item-level import fields. Value should not be changed.
DataMapping.ImportFields.Item["AeonDefault"] = {
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

DataMapping.ImportFields.Item["ILLiadDefault"] = {
    {
        Table = "Transaction",
        LoanField = "ReferenceNumber", ArticleField = "ReferenceNumber",
        MaxSize = 50,
        Value = "ReferenceNumber"
    },
    {
        Table = "Transaction",
        LoanField = "CallNumber", ArticleField = "CallNumber",
        MaxSize = 100,
        Value = "CallNumber"
    },
    {
        Table = "Transaction",
        LoanField = "ItemNumber", ArticleField = "ItemNumber",
        MaxSize = 20,
        Value = "Barcode"
    },
    {
        Table = "Transaction",
        LoanField = "Location", ArticleField = "Location",
        MaxSize = 255,
        Value = "Location"
    }
};

DataMapping.ImportFields.Item["AresDefault"] = {
    {
        Table = "Item",
        Field = "ReferenceNumber", MaxSize = 50,
        Value = "ReferenceNumber"
    },
    {
        Table = "Item",
        Field = "Callnumber", MaxSize = 100,
        Value = "CallNumber"
    },
    {
        Table = "Item",
        Field = "ItemBarcode", MaxSize = 50,
        Value = "Barcode"
    },
    {
        Table = "Item",
        Field = "ShelfLocation", MaxSize = 100,
        Value = "Location"
    }
};

DataMapping.ImportFields.Item["ILLiadDefault"] = {
    {
        Table = "Transaction",
        LoanField = "ReferenceNumber", ArticleField = "ReferenceNumber",
        MaxSize = 50,
        Value = "ReferenceNumber"
    },
    {
        Table = "Transaction",
        LoanField = "CallNumber", ArticleField = "CallNumber",
        MaxSize = 100,
        Value = "CallNumber"
    },
    {
        Table = "Transaction",
        LoanField = "ItemNumber", ArticleField = "ItemNumber",
        MaxSize = 20,
        Value = "Barcode"
    },
    {
        Table = "Transaction",
        LoanField = "Location", ArticleField = "Location",
        MaxSize = 255,
        Value = "Location"
    }
};

DataMapping.ImportFields.Item["AresDefault"] = {
    {
        Table = "Item",
        Field = "ReferenceNumber", MaxSize = 50,
        Value = "ReferenceNumber"
    },
    {
        Table = "Item",
        Field = "Callnumber", MaxSize = 100,
        Value = "CallNumber"
    },
    {
        Table = "Item",
        Field = "ItemBarcode", MaxSize = 50,
        Value = "Barcode"
    },
    {
        Table = "Item",
        Field = "ShelfLocation", MaxSize = 100,
        Value = "Location"
    }
};