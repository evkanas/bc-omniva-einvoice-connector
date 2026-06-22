page 70101 "EVK Omniva Export"
{
    PageType = Card;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    Caption = 'Omniva Export', Comment = 'lt-LT="Omniva eksportas"';
    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(VendorFilter; VendorFilter)
                {
                    Caption = 'Vendors', Comment = 'lt-LT="Tiekėjai"';
                    ApplicationArea = All;
                    ToolTip = 'Specifies vendors filter.', Comment = 'lt-LT="Nurodo tiekėjų filtrą"';
                    TableRelation = Vendor;
                    trigger OnDrillDown()
                    begin
                        Clear(EVKOmniva);
                        EVKOmniva.ExportVendors(VendorFilter, false);
                    end;
                }
                field(DimensionFilter; DimensionFilter)
                {
                    Caption = 'Dimensions', Comment = 'lt-LT="Dimensijos"';
                    ApplicationArea = All;
                    ToolTip = 'Specifies dimensions filter.', Comment = 'lt-LT="Nurodo dimensijų filtrą"';
                    TableRelation = Dimension;
                    trigger OnDrillDown()
                    begin
                        ExportDimensions();
                    end;
                }
                field(ChartOfAccountsFilter; ChartOfAccountsFilter)
                {
                    Caption = 'Chart of Accounts', Comment = 'lt-LT="Sąskaitų planas"';
                    ApplicationArea = All;
                    ToolTip = 'Specifies g/l account filter.', Comment = 'lt-LT="Nurodo galinės sąskaitos filtrą"';
                    TableRelation = "G/L Account";
                    trigger OnDrillDown()
                    begin
                        ExportChartOfAccounts();
                    end;
                }
                field(LocationCodeFilter; LocationCodeFilter)
                {
                    Caption = 'Location Code', Comment = 'lt-LT="Vietai kodas"';
                    ApplicationArea = All;
                    ToolTip = 'Specifies location code filter.', Comment = 'lt-LT="Nurodo vietos kodo filtrą"';
                    TableRelation = Location;
                    trigger OnDrillDown()
                    begin
                        ExportLocation();
                    end;
                }
                field(ItemFilter; ItemFilter)
                {
                    Caption = 'Item', Comment = 'lt-LT="Prekės"';
                    ApplicationArea = All;
                    ToolTip = 'Specifies item filter.', Comment = 'lt-LT="Nurodo prekių filtrą"';
                    TableRelation = Item;
                    trigger OnDrillDown()
                    begin
                        ExportItem();
                    end;
                }
                field(InvoiceImportDate; InvoiceImportDate)
                {
                    Caption = 'Import From', Comment = 'lt-LT="Importuoti nuo"';
                    ApplicationArea = All;
                    ToolTip = 'Specifies e-invoice import date from.', Comment = 'lt-LT="Nurodo e-sąskaitų importo datą nuo"';
                    trigger OnDrillDown()
                    var
                        EVKOmniva: Codeunit "EVK Omniva";
                    begin

                        Clear(EVKOmniva);
                        EVKOmniva.OmnivaInvoiceImport(FORMAT(InvoiceImportDate, 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00:00');
                    end;
                }
            }
        }
    }
    trigger OnOpenPage()

    begin
        InvoiceImportDate := WORKDATE();
    end;

    procedure ExportChartOfAccounts()
    var
        GLAccount: Record "G/L Account";
        AccountPlanRequestNode: XmlNode;
        AccountPlansElement: XmlElement;
        AccountPlanElement: XmlElement;

    begin
        Clear(EVKOmniva);
        EVKOmniva.Setup(ServiceUrl, AuthorizationToken);
        Clear(ProgressDialog);
        ProgressDialog.OPEN(CalculatingLbl);
        Clear(RequestText);
        EVKOmniva.CreateXMLText(AuthorizationToken, RequestText, 'AccountPlanRequest');
        Clear(DocXmlDocument);
        EVKOmniva.CreateDocXmlDocument(RequestText, DocXmlDocument, Envelope, BodyList, DocumentNodes, EnvelopeNode, BodyNode);
        BodyList.Get(1, AccountPlanRequestNode);

        AccountPlansElement := XmlElement.Create('Kontoplaanid');
        AccountPlanRequestNode.AsXmlElement().Add(AccountPlansElement);

        ProcessedCount := 1;
        Clear(GLAccount);
        GLAccount.Reset();
        GLAccount.SetFilter(GLAccount."No.", ChartOfAccountsFilter);
        GLAccount.SetRange(Omniva, true);
        TotalCount := GLAccount.COUNT;

        if GLAccount.FINDset() then
            repeat
                ProgressDialog.UPDATE(1, ROUND(10000 * ProcessedCount / TotalCount, 1));
                ProcessedCount += 1;
                AccountPlanElement := XmlElement.Create('Kontoplaan');
                AccountPlansElement.Add(AccountPlanElement);

                Clear(ValueElement);
                ValueElement := XmlElement.Create('AccountNum');
                TextNode := XmlText.Create(GLAccount."No.");
                ValueElement.Add(TextNode);
                AccountPlanElement.Add(ValueElement);

                Clear(ValueElement);
                ValueElement := XmlElement.Create('AccountName');
                TextNode := XmlText.Create(GLAccount.Name);
                ValueElement.Add(TextNode);
                AccountPlanElement.Add(ValueElement);
            until GLAccount.Next() = 0;
        ProgressDialog.Close();
        EVKOmniva.HttpClientSend(RequestText, DocXmlDocument, ServiceUrl, false);

    end;

    procedure ExportItem()
    var
        Item: Record Item;
        DimensionRegistryRequestNode: XmlNode;
        DimensionsElement: XmlElement;
        DimensionGroupElement: XmlElement;
        DimensionCodeElement: XmlElement;
    begin
        clear(EVKOmniva);
        EVKOmniva.Setup(ServiceUrl, AuthorizationToken);
        Clear(ProgressDialog);
        ProgressDialog.OPEN(CalculatingLbl);
        Clear(RequestText);
        EVKOmniva.CreateXMLText(AuthorizationToken, RequestText, 'DimensionRegistryRequest');
        Clear(DocXmlDocument);
        EVKOmniva.CreateDocXmlDocument(RequestText, DocXmlDocument, Envelope, BodyList, DocumentNodes, EnvelopeNode, BodyNode);
        BodyList.Get(1, DimensionRegistryRequestNode);
        DimensionsElement := XmlElement.Create('Dimensioonid');
        DimensionRegistryRequestNode.AsXmlElement().Add(DimensionsElement);
        ProcessedCount := 1;

        Clear(Item);
        Item.Reset();
        Item.SetFilter("No.", ItemFilter);
        Item.SetRange(Omniva, true);
        TotalCount := Item.COUNT;

        if not Item.IsEmpty then begin
            DimensionGroupElement := XmlElement.Create('Bendraspavadinimas');
            DimensionsElement.Add(DimensionGroupElement);

            if Item.FINDset() then
                repeat
                    ProgressDialog.UPDATE(1, ROUND(10000 * ProcessedCount / TotalCount, 1));
                    ProcessedCount += 1;

                    DimensionCodeElement := XmlElement.Create('PREKE');
                    DimensionGroupElement.Add(DimensionCodeElement);

                    Clear(ValueElement);
                    ValueElement := XmlElement.Create('Num');
                    TextNode := XmlText.Create(Item."No.");
                    ValueElement.Add(TextNode);
                    DimensionCodeElement.Add(ValueElement);

                    Clear(ValueElement);
                    ValueElement := XmlElement.Create('Description');
                    TextNode := XmlText.Create(Item.Description);
                    ValueElement.Add(TextNode);
                    DimensionCodeElement.Add(ValueElement);
                until Item.Next() = 0;
            ProgressDialog.Close();
            EVKOmniva.HttpClientSend(RequestText, DocXmlDocument, ServiceUrl, false);
        end;
    end;

    procedure ExportLocation()
    var
        Location: Record Location;
        DimensionRegistryRequestNode: XmlNode;
        DimensionsElement: XmlElement;
        DimensionGroupElement: XmlElement;
        DimensionCodeElement: XmlElement;
    begin
        clear(EVKOmniva);
        EVKOmniva.Setup(ServiceUrl, AuthorizationToken);
        Clear(ProgressDialog);
        ProgressDialog.OPEN(CalculatingLbl);
        Clear(RequestText);
        EVKOmniva.CreateXMLText(AuthorizationToken, RequestText, 'DimensionRegistryRequest');
        clear(DocXmlDocument);
        EVKOmniva.CreateDocXmlDocument(RequestText, DocXmlDocument, Envelope, BodyList, DocumentNodes, EnvelopeNode, BodyNode);
        BodyList.Get(1, DimensionRegistryRequestNode);
        DimensionsElement := XmlElement.Create('Dimensioonid');
        DimensionRegistryRequestNode.AsXmlElement().Add(DimensionsElement);
        ProcessedCount := 1;

        Clear(Location);
        Location.Reset();
        Location.SetFilter(Code, LocationCodeFilter);
        Location.SetRange(Omniva, true);
        TotalCount := Location.COUNT;

        if not Location.IsEmpty then begin
            DimensionGroupElement := XmlElement.Create('Bendraspavadinimas');
            DimensionsElement.Add(DimensionGroupElement);

            if Location.FINDset() then
                repeat
                    ProgressDialog.UPDATE(1, ROUND(10000 * ProcessedCount / TotalCount, 1));
                    ProcessedCount += 1;

                    DimensionCodeElement := XmlElement.Create('SANDELIS');
                    DimensionGroupElement.Add(DimensionCodeElement);

                    Clear(ValueElement);
                    ValueElement := XmlElement.Create('Num');
                    TextNode := XmlText.Create(Location.Code);
                    ValueElement.Add(TextNode);
                    DimensionCodeElement.Add(ValueElement);

                    Clear(ValueElement);
                    ValueElement := XmlElement.Create('Description');
                    TextNode := XmlText.Create(Location.Name);
                    ValueElement.Add(TextNode);
                    DimensionCodeElement.Add(ValueElement);
                until Location.Next() = 0;
            ProgressDialog.Close();
            EVKOmniva.HttpClientSend(RequestText, DocXmlDocument, ServiceUrl, false);
        end;
    end;

    procedure ExportDimensions()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionRegistryRequestNode: XmlNode;
        DimensionsElement: XmlElement;
        DimensionGroupElement: XmlElement;
        DimensionCodeElement: XmlElement;
    begin
        clear(EVKOmniva);
        EVKOmniva.Setup(ServiceUrl, AuthorizationToken);
        Clear(ProgressDialog);
        ProgressDialog.OPEN(CalculatingLbl);
        Clear(RequestText);
        EVKOmniva.CreateXMLText(AuthorizationToken, RequestText, 'DimensionRegistryRequest');
        clear(DocXmlDocument);
        EVKOmniva.CreateDocXmlDocument(RequestText, DocXmlDocument, Envelope, BodyList, DocumentNodes, EnvelopeNode, BodyNode);

        BodyList.Get(1, DimensionRegistryRequestNode);

        DimensionsElement := XmlElement.Create('Dimensioonid');

        DimensionRegistryRequestNode.AsXmlElement().Add(DimensionsElement);

        ProcessedCount := 1;
        Clear(Dimension);
        Dimension.Reset();
        Dimension.SetFilter(Code, DimensionFilter);
        TotalCount := Dimension.COUNT;
        if Dimension.FINDset() then
            repeat
                ProgressDialog.UPDATE(1, ROUND(10000 * ProcessedCount / TotalCount, 1));
                ProcessedCount += 1;
                Clear(DimensionValue);
                DimensionValue.Reset();
                DimensionValue.SetRange("Dimension Code", Dimension.Code);
                DimensionValue.SetRange(Omniva, true);
                DimensionValue.SetRange(Blocked, false);
                if not DimensionValue.IsEmpty then begin
                    DimensionGroupElement := XmlElement.Create('Bendraspavadinimas');
                    DimensionsElement.Add(DimensionGroupElement);
                    if DimensionValue.FINDSET() then
                        repeat
                            if Dimension.Code = 'VK PROJEKTAI' then
                                DimensionCodeElement := XmlElement.Create('VK_PROJEKTAI')
                            else
                                DimensionCodeElement := XmlElement.Create(Dimension.Code);
                            DimensionGroupElement.Add(DimensionCodeElement);

                            Clear(ValueElement);
                            ValueElement := XmlElement.Create('Num');
                            TextNode := XmlText.Create(DimensionValue.Code);
                            ValueElement.Add(TextNode);
                            DimensionCodeElement.Add(ValueElement);

                            Clear(ValueElement);

                            ValueElement := XmlElement.Create('Description');
                            TextNode := XmlText.Create(DimensionValue.Name);
                            ValueElement.Add(TextNode);
                            DimensionCodeElement.Add(ValueElement);
                        until DimensionValue.Next() = 0;
                end;
            until Dimension.Next() = 0;
        ProgressDialog.Close();
        EVKOmniva.HttpClientSend(RequestText, DocXmlDocument, ServiceUrl, false);
    end;

    var
        EVKOmniva: Codeunit "EVK Omniva";
        ProgressDialog: Dialog;
        CalculatingLbl: label 'Calculating @1@@@@@@@@@@@@@@@@@@@';
        RequestText: text;
        AuthorizationToken: text;
        ServiceUrl: text;
        VendorFilter: text;
        DimensionFilter: text;
        ChartOfAccountsFilter: text;
        LocationCodeFilter: text;
        ItemFilter: text;
        InvoiceImportDate: date;
        DocXmlDocument: XmlDocument;
        Envelope: XmlNodeList;
        BodyList: XmlNodeList;
        DocumentNodes: XmlNodeList;
        EnvelopeNode: XmlNode;
        BodyNode: XmlNode;
        ValueElement: XmlElement;
        TextNode: XmlText;
        TotalCount: Integer;
        ProcessedCount: Integer;
}
