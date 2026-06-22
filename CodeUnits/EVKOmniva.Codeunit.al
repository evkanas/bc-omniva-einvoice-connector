codeunit 70100 "EVK Omniva"
{
    TableNo = "Job Queue Entry";
    trigger OnRun()
    begin
        Rec.TESTFIELD("Parameter String");
        case COPYSTR(Rec."Parameter String", 1, 2) OF
            'CD':
                OmnivaInvoiceImport(COPYSTR(Rec."Parameter String", 3, 1));
            'OA':
                OmnivaAutopost();
            'IV':
                ImportVendorToOmniva();
            'OT':
                OmnivaTest();
            else
                ERROR(InvalidParametersErr);
        end;
    end;

    procedure ImportVendorToOmniva()
    begin
        ExportVendors('', true);
    end;

    procedure OmnivaAutopost()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ContinueProcess: Boolean;
    begin
        Clear(PurchasesPayablesSetup);
        PurchasesPayablesSetup.Reset();
        PurchasesPayablesSetup.Get();
        Clear(PurchaseHeader);
        PurchaseHeader.Reset();
        PurchaseHeader.SetFilter("No.", 'OPIRK*');
        PurchaseHeader.SetRange("Omniva Autopost", true);
        PurchaseHeader.SetRange(Status, PurchaseHeader.Status::Released);
        PurchaseHeader.SetFilter("Reason Code", '<>%1', '');
        PurchaseHeader.SetFilter("Vendor Invoice No.", '<>%1', '');
        ContinueProcess := true;
        if PurchaseHeader.FindSet() then
            repeat
                ContinueProcess := true;
                if PurchasesPayablesSetup."Ext. Doc. No. Mandatory" then begin
                    Clear(VendorLedgerEntry);
                    VendorLedgerEntry.Reset();
                    VendorLedgerEntry.SETCURRENTKEY("External Document No.");
                    VendorLedgerEntry.SetRange("External Document No.", PurchaseHeader."Vendor Invoice No.");
                    VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Pay-to Vendor No.");
                    VendorLedgerEntry.SetRange(Reversed, false);
                    if not VendorLedgerEntry.IsEmpty then ContinueProcess := false;
                end;
                Clear(GeneralLedgerSetup);
                GeneralLedgerSetup.Reset();
                GeneralLedgerSetup.Get();

                if PurchaseHeader."Posting Date" < GeneralLedgerSetup."Allow Posting From" then ContinueProcess := false;

                if ContinueProcess then
                    CODEUNIT.RUN(90, PurchaseHeader);

            until PurchaseHeader.Next() = 0;
    end;

    procedure OmnivaTest()
    var
        TempEVKOmnivaHeader: Record "EVK Omniva Header" temporary;
        TempEVKOmnivaLines: Record "EVK Omniva Lines" temporary;
        TempEVKOmnivaDimensions: Record "EVK Omniva Dimensions" temporary;
        LineFeedCharacter: Char;
        MessageText: Text;
        SelectedFileName: Text;
        ProformaInvoiceText: Text[200];
        ErrorMessageText: Text[200];
        TotalInvoiceCount: Integer;
        CreatedInvoiceCount: Integer;
        InStream: InStream;
        SelectFileLbl: Label 'Select file', Comment = 'lt-LT="Pasirinkite failą"';

    begin
        LineFeedCharacter := 10;
        ProformaInvoiceText := '';
        TotalInvoiceCount := 0;
        CreatedInvoiceCount := 0;
        XmlRequestText := '';
        ErrorMessageText := '';
        if not UploadIntoStream(SelectFileLbl, '', '*.xml*|*.*', SelectedFileName, InStream) then
            exit;
        clear(DocXmlDocument);
        if not XmlDocument.ReadFrom(InStream, DocXmlDocument) then
            Error(InvalidXmlFileErr);
        OmnivaImportavimas(TempEVKOmnivaHeader, TempEVKOmnivaDimensions, TempEVKOmnivaLines);
        CheckPurchaseInvoiceImport(ErrorMessageText, TempEVKOmnivaHeader, TempEVKOmnivaLines, TempEVKOmnivaDimensions);
        CreatePurchaseInvoice(ProformaInvoiceText, TempEVKOmnivaHeader, TempEVKOmnivaLines, TempEVKOmnivaDimensions, TotalInvoiceCount, CreatedInvoiceCount);
        if GUIALLOWED then begin
            if ErrorMessageText <> '' then
                ErrorMessageText := ';' + FORMAT(LineFeedCharacter) + 'Yra klaidų (žiūr. log informaciją)!';
            if ProformaInvoiceText <> '' then
                ProformaInvoiceText := ';' + FORMAT(LineFeedCharacter) + 'Yra išanskt. sąskaita (žiūr. log informaciją)!';

            MessageText := 'Viso SF (su kred) ' + FORMAT(TotalInvoiceCount) + ', pavyko sukurti ' + FORMAT(CreatedInvoiceCount) + ErrorMessageText + ProformaInvoiceText;
            MESSAGE(MessageText);
        end;
    end;

    procedure OmnivaImportavimas(var EVKOmnivaHeader: Record "EVK Omniva Header" TEMPORARY; var EVKOmnivaDimensions: Record "EVK Omniva Dimensions" TEMPORARY; var EVKOmnivaLines: Record "EVK Omniva Lines" TEMPORARY)
    var
        BuyInvoicesResponseList: XmlNodeList;
        EInvoiceList: XmlNodeList;
        XmlNodes: XmlNodeList;
        InvoiceList: XmlNodeList;
        InvoicePartiesList: XmlNodeList;
        InvoiceInformationList: XmlNodeList;
        InvoiceSumGroupList: XmlNodeList;
        InvoiceItemList: XmlNodeList;
        SellerPartyList: XmlNodeList;
        UniqueCodeList: XmlNodeList;
        TypeList: XmlNodeList;
        PaymentInfoList: XmlNodeList;
        ContractNumberList: XmlNodeList;
        ExtensionList: XmlNodeList;
        InvoiceItemGroupList: XmlNodeList;
        ItemEntryList: XmlNodeList;
        JournalEntryList: XmlNodeList;
        CustomContentList: XmlNodeList;
        CostObjectivesList: XmlNodeList;
        AccountingList: XmlNodeList;
        ItemReserveList: XmlNodeList;
        ItemDetailInfoList: XmlNodeList;
        BuyInvoicesResponseNode: XmlNode;
        EInvoiceNode: XmlNode;
        InvoiceNode: XmlNode;
        CurrentXmlNode: XmlNode;
        InvoicePartiesNode: XmlNode;
        XmlNodeLevel3: XmlNode;
        XmlNodeLevel4: XmlNode;
        XmlNodeLevel5: XmlNode;
        XmlNodeLevel6: XmlNode;
        XmlNodeLevel7: XmlNode;

        XmlNodeLevel2: XmlNode;
        UniqueCodeNode: XmlNode;
        InvoiceAttributes: XmlAttributeCollection;
        CurrentXmlAttribute: XmlAttribute;
        i: integer;
        j: integer;
        k: integer;
        m: integer;
        n: integer;
        o: integer;
        p: integer;
        l: integer;
        q: integer;
        HeaderId: Integer;
        DimensionRowID: Integer;
        LineNo: integer;
        OmnivaInvoiceId: code[20];
        VendorCompanyCode: code[50];
        VendorNo: code[20];
        AppliesToInvoiceNo: code[20];
        VendorInvoiceNo: code[20];
        AssignedNo: code[20];
        DimensionCode: code[20];
        DimensionValueCode: code[20];
        UnitOfMeasureCode: code[10];
        BankAccountNo: code[50];
        NodeName: text;
        InvoiceType: text[30];
        ResultText: text[250];
        IncludesLatest: text[5];
        LatestChange: text[30];
        ResultCode: text[30];
        InvoiceLabelName: text[30];
        InvoiceLabelValue: text[30];
        CurrencyCode: text[3];
        Description1: text[50];
        Description2: text[50];

        LineAmount: decimal;
        ItemQuantity: decimal;
        ItemPrice: decimal;
        ParsedDate: date;
    begin
        DocXmlDocument.WriteTo(NodeName);
        NodeName := '';
        EVKOmnivaSetup.Get();
        OmnivaInvoiceId := '';

        DocumentNodes := DocXmlDocument.GetChildNodes();
        DocumentNodes.Get(1, EnvelopeNode);

        Envelope := EnvelopeNode.AsXmlElement().GetChildElements();
        Envelope.Get(2, BodyNode);
        BodyList := BodyNode.AsXmlElement().GetChildElements();
        BodyList.Get(1, BuyInvoicesResponseNode);

        BuyInvoicesResponseList := BuyInvoicesResponseNode.AsXmlElement().GetChildElements();
        BuyInvoicesResponseList.Get(1, EInvoiceNode);

        EInvoiceList := EInvoiceNode.AsXmlElement().GetChildElements();
        EInvoiceList.Get(2, InvoiceNode);

        for i := 0 TO EInvoiceList.Count - 1 do begin
            EInvoiceList.Get(i + 1, CurrentXmlNode);
            NodeName := CurrentXmlNode.AsXmlElement().Name;
            if NodeName = 'Invoice' then begin
                HeaderId := 1;
                Clear(EVKOmnivaHeader);
                EVKOmnivaHeader.Reset();
                if EVKOmnivaHeader.FINDLAST() then HeaderId := EVKOmnivaHeader.id + 1;
                Clear(EVKOmnivaHeader);
                EVKOmnivaHeader.Reset();
                EVKOmnivaHeader.INIT();
                EVKOmnivaHeader.id := HeaderId;
                EVKOmnivaHeader.INSERT();
                OmnivaInvoiceId := '';
                VendorCompanyCode := '';
                VendorNo := '';
                AppliesToInvoiceNo := '';

                if CurrentXmlNode.AsXmlElement().HasAttributes() then begin
                    InvoiceAttributes := CurrentXmlNode.AsXmlElement().Attributes();
                    for j := 0 TO InvoiceAttributes.Count - 1 DO begin
                        InvoiceAttributes.Get(j + 1, CurrentXmlAttribute);
                        NodeName := CurrentXmlAttribute.Name;
                        if NodeName = 'invoiceId' then
                            OmnivaInvoiceId := copystr(CurrentXmlAttribute.Value, 1, MaxStrLen(OmnivaInvoiceId));
                        if NodeName = 'sellerRegNumber' then
                            VendorCompanyCode := copystr(CurrentXmlAttribute.Value, 1, MaxStrLen(VendorCompanyCode));
                    end;
                end;
                EVKOmnivaHeader."Omniva SF ID" := OmnivaInvoiceId;
                XmlNodes := CurrentXmlNode.AsXmlElement().GetChildElements();
                XmlNodes.Get(1, InvoicePartiesNode);

                InvoiceList := CurrentXmlNode.AsXmlElement().GetChildElements();
                Clear(InvoicePartiesList);
                Clear(InvoiceInformationList);
                Clear(InvoiceItemList);
                Clear(PaymentInfoList);
                Clear(InvoiceSumGroupList);
                Clear(SellerPartyList);
                Clear(UniqueCodeList);
                Clear(TypeList);
                Clear(ContractNumberList);
                Clear(ExtensionList);
                Clear(InvoiceItemGroupList);
                Clear(ItemEntryList);
                Clear(JournalEntryList);
                Clear(CustomContentList);
                Clear(CostObjectivesList);
                Clear(AccountingList);
                Clear(ItemReserveList);
                Clear(ItemDetailInfoList);
                for j := 0 to InvoiceList.Count() - 1 DO begin
                    InvoiceList.Get(j + 1, XmlNodeLevel2);
                    NodeName := XmlNodeLevel2.AsXmlElement().Name;
                    if NodeName = 'InvoiceParties' then
                        InvoicePartiesList := XmlNodeLevel2.AsXmlElement().GetChildElements();
                    if NodeName = 'InvoiceInformation' then
                        InvoiceInformationList := XmlNodeLevel2.AsXmlElement().GetChildElements();

                    if NodeName = 'InvoiceSumGroup' then
                        InvoiceSumGroupList := XmlNodeLevel2.AsXmlElement().GetChildElements();


                    if NodeName = 'InvoiceItem' then
                        InvoiceItemList := XmlNodeLevel2.AsXmlElement().GetChildElements();

                    if NodeName = 'PaymentInfo' then
                        PaymentInfoList := XmlNodeLevel2.AsXmlElement().GetChildElements();
                end;

                if InvoicePartiesList.count > 0 then begin
                    for j := 0 TO InvoicePartiesList.Count - 1 DO begin
                        InvoicePartiesList.Get(j + 1, XmlNodeLevel2);
                        NodeName := XmlNodeLevel2.AsXmlElement().Name;
                        if NodeName = 'SellerParty' then
                            SellerPartyList := XmlNodeLevel2.AsXmlElement().GetChildElements();
                    end;

                    if SellerPartyList.count > 0 then begin
                        for j := 0 TO SellerPartyList.Count - 1 DO begin
                            SellerPartyList.Get(j + 1, XmlNodeLevel2);
                            NodeName := XmlNodeLevel2.AsXmlElement().Name;
                            if NodeName = 'UniqueCode' then
                                UniqueCodeList := XmlNodeLevel2.AsXmlElement().GetChildElements();
                        end;
                        if UniqueCodeList.count > 0 then begin
                            UniqueCodeList.Get(1, UniqueCodeNode);
                            VendorNo := copystr(UniqueCodeNode.AsXmlElement().InnerText, 1, MaxStrLen(VendorNo));
                        end
                    end;
                end;

                EVKOmnivaHeader."Vendor Company Code" := COPYSTR(VendorCompanyCode, 1, MaxStrLen(EVKOmnivaHeader."Vendor Company Code"));
                EVKOmnivaHeader."Vendor Navision No." := VendorNo;
                if InvoiceInformationList.count > 0 then begin
                    AppliesToInvoiceNo := '';
                    InvoiceType := '';
                    clear(TypeList);
                    clear(ContractNumberList);
                    clear(ExtensionList);
                    for j := 0 TO InvoiceInformationList.Count - 1 DO begin
                        InvoiceInformationList.Get(j + 1, XmlNodeLevel2);
                        NodeName := XmlNodeLevel2.AsXmlElement().Name;
                        if NodeName = 'Type' then begin
                            InvoiceAttributes := XmlNodeLevel2.AsXmlElement().Attributes();
                            for k := 0 TO InvoiceAttributes.Count - 1 DO begin
                                InvoiceAttributes.Get(k + 1, CurrentXmlAttribute);
                                NodeName := CurrentXmlAttribute.Name;
                                if NodeName = 'type' then begin
                                    InvoiceType := copystr(CurrentXmlAttribute.Value, 1, MaxStrLen(InvoiceType));
                                    EVKOmnivaHeader."Invoice Type" := copystr(InvoiceType, 1, MaxStrLen(EVKOmnivaHeader."Invoice Type"));
                                end;
                            end;
                            if LowerCase(InvoiceType) = 'cre' then begin
                                TypeList := XmlNodeLevel2.AsXmlElement().GetChildElements();
                                if TypeList.count > 0 then begin
                                    TypeList.Get(1, XmlNodeLevel3);
                                    NodeName := XmlNodeLevel3.AsXmlElement().Name;
                                    if NodeName = 'SourceInvoice' then begin
                                        AppliesToInvoiceNo := copystr(XmlNodeLevel3.AsXmlElement().InnerText, 1, MaxStrLen(AppliesToInvoiceNo));
                                        EVKOmnivaHeader."Applies-to Invoice No." := AppliesToInvoiceNo;
                                    end;
                                end;
                            end
                        end;

                        if NodeName = 'InvoiceDate' then begin
                            ResultText := copystr(XmlNodeLevel2.AsXmlElement().InnerText, 1, MaxStrLen(ResultText));
                            ParsedDate := ParseXmlDate(ResultText);
                            EVKOmnivaHeader."Posting Date" := ParsedDate;
                        end;
                        if NodeName = 'DueDate' then begin
                            ResultText := copystr(XmlNodeLevel2.AsXmlElement().InnerText, 1, MaxStrLen(ResultText));
                            ParsedDate := ParseXmlDate(ResultText);
                            EVKOmnivaHeader."Due Date" := ParsedDate;
                        end;
                        if NodeName = 'InvoiceNumber' then begin
                            ResultText := copystr(XmlNodeLevel2.AsXmlElement().InnerText, 1, MaxStrLen(ResultText));
                            VendorInvoiceNo := COPYSTR(ResultText, 1, MaxStrLen(VendorInvoiceNo));
                            VendorInvoiceNo := PasalintiSimbolius(VendorInvoiceNo);
                            EVKOmnivaHeader."Vendor Invoice No." := VendorInvoiceNo;
                        end;

                        if NodeName = 'Extension' then begin
                            ExtensionList := XmlNodeLevel2.AsXmlElement().GetChildElements();
                            ResultCode := '';
                            InvoiceAttributes := XmlNodeLevel2.AsXmlElement().Attributes();
                            for k := 0 TO InvoiceAttributes.Count - 1 DO begin
                                InvoiceAttributes.Get(k + 1, CurrentXmlAttribute);
                                NodeName := CurrentXmlAttribute.Name;
                                if NodeName = 'extensionId' then begin
                                    ResultCode := copystr(CurrentXmlAttribute.Value, 1, MaxStrLen(ResultCode));
                                    if ResultCode = 'erpAccountingDocNr' then begin
                                        AssignedNo := '';
                                        for m := 0 TO ExtensionList.Count - 1 DO begin
                                            ExtensionList.Get(m + 1, XmlNodeLevel3);
                                            NodeName := XmlNodeLevel3.AsXmlElement().Name;
                                            if NodeName = 'InformationContent' then begin
                                                AssignedNo := copystr(XmlNodeLevel3.AsXmlElement().InnerText, 1, MaxStrLen(AssignedNo));
                                                EVKOmnivaHeader."Assigned No." := AssignedNo;
                                            end;
                                        end;
                                    end
                                    else
                                        if ResultCode = 'eakAdditionalField' then begin
                                            InvoiceLabelName := '';
                                            InvoiceLabelValue := '';
                                            for m := 0 TO ExtensionList.Count - 1 DO begin
                                                ExtensionList.Get(m + 1, XmlNodeLevel3);
                                                NodeName := XmlNodeLevel3.AsXmlElement().Name;
                                                if NodeName = 'InformationName' then
                                                    InvoiceLabelName := copystr(XmlNodeLevel3.AsXmlElement().InnerText, 1, MaxStrLen(AssignedNo));

                                                if NodeName = 'InformationContent' then
                                                    InvoiceLabelValue := copystr(XmlNodeLevel3.AsXmlElement().InnerText, 1, MaxStrLen(AssignedNo));
                                            end;
                                            if LowerCase(InvoiceLabelName) = 'sf požymis' then
                                                EVKOmnivaHeader."SF Label" := InvoiceLabelValue;
                                        end;
                                end;
                            end;
                        end;
                    end;
                end;

                if InvoiceSumGroupList.count > 0 then
                    For j := 0 TO InvoiceSumGroupList.Count - 1 DO begin
                        InvoiceSumGroupList.Get(j + 1, XmlNodeLevel2);
                        NodeName := XmlNodeLevel2.AsXmlElement().Name;
                        if NodeName = 'TotalVATSum' then begin
                            ResultText := copystr(XmlNodeLevel2.AsXmlElement().InnerText, 1, MaxStrLen(ResultText));
                            EVKOmnivaHeader."Total VAT Sum" := ParseXmlDecimal(ResultText);
                        end;
                    end;

                if PaymentInfoList.count > 0 then begin
                    CurrencyCode := '';
                    BankAccountNo := '';
                    for j := 0 TO PaymentInfoList.Count - 1 DO begin
                        PaymentInfoList.Get(j + 1, XmlNodeLevel2);
                        NodeName := XmlNodeLevel2.AsXmlElement().Name;
                        if NodeName = 'Currency' then begin
                            ResultText := copystr(XmlNodeLevel2.AsXmlElement().InnerText, 1, MaxStrLen(ResultText));
                            CurrencyCode := copystr(ResultText, 1, MaxStrLen(CurrencyCode));
                        end;
                        if NodeName = 'PayToAccount' then begin
                            ResultText := copystr(XmlNodeLevel2.AsXmlElement().InnerText, 1, MaxStrLen(ResultText));
                            BankAccountNo := copystr(ResultText, 1, MaxStrLen(BankAccountNo));
                        end;
                    end;
                    if (CurrencyCode = 'EUR') OR (CurrencyCode = 'eur') then CurrencyCode := '';
                    if CurrencyCode <> '' then
                        EVKOmnivaHeader."Currency Code" := CurrencyCode;
                    if BankAccountNo <> '' then
                        EVKOmnivaHeader."Bank Account No." := copystr(BankAccountNo, 1, MaxStrLen(EVKOmnivaHeader."Bank Account No."));
                end;
                EVKOmnivaHeader.Modify();

                if InvoiceItemList.count > 0 then begin
                    clear(InvoiceItemGroupList);
                    for j := 0 TO InvoiceItemList.Count - 1 DO begin
                        InvoiceItemList.Get(j + 1, XmlNodeLevel2);
                        NodeName := XmlNodeLevel2.AsXmlElement().Name;
                        if NodeName = 'InvoiceItemGroup' then begin
                            InvoiceItemGroupList := XmlNodeLevel2.AsXmlElement().GetChildElements();
                            for k := 0 TO InvoiceItemGroupList.Count - 1 DO begin
                                InvoiceItemGroupList.Get(k + 1, XmlNodeLevel3);
                                NodeName := XmlNodeLevel3.AsXmlElement().Name;
                                if NodeName = 'ItemEntry' then begin
                                    ItemEntryList := XmlNodeLevel3.AsXmlElement().GetChildElements();

                                    Clear(EVKOmnivaLines);
                                    EVKOmnivaLines.Reset();
                                    LineNo := 10000;
                                    if EVKOmnivaLines.FINDLAST() then LineNo := EVKOmnivaLines.id + 10000;
                                    Clear(EVKOmnivaLines);
                                    EVKOmnivaLines.Reset();
                                    EVKOmnivaLines.INIT();
                                    EVKOmnivaLines."Header ID" := EVKOmnivaHeader.id;
                                    EVKOmnivaLines.ID := LineNo;
                                    for m := 0 TO ItemEntryList.Count - 1 DO begin
                                        ItemEntryList.Get(m + 1, XmlNodeLevel4);
                                        NodeName := XmlNodeLevel4.AsXmlElement().Name;
                                        if NodeName = 'Accounting' then begin
                                            AccountingList := XmlNodeLevel4.AsXmlElement().GetChildElements();
                                            for n := 0 TO AccountingList.Count - 1 DO begin
                                                AccountingList.Get(n + 1, XmlNodeLevel5);
                                                NodeName := XmlNodeLevel5.AsXmlElement().Name;
                                                if NodeName = 'JournalEntry' then begin
                                                    JournalEntryList := XmlNodeLevel5.AsXmlElement().GetChildElements();
                                                    for o := 0 TO JournalEntryList.Count - 1 DO begin
                                                        JournalEntryList.Get(o + 1, XmlNodeLevel6);
                                                        NodeName := XmlNodeLevel6.AsXmlElement().Name;
                                                        if NodeName = 'GeneralLedger' then begin
                                                            ResultText := copystr(XmlNodeLevel6.AsXmlElement().InnerText, 1, MaxStrLen(ResultText));
                                                            EVKOmnivaLines."G/L Account Code" := copystr(ResultText, 1, MaxStrLen(EVKOmnivaLines."G/L Account Code"));
                                                        end;
                                                        if NodeName = 'Sum' then begin
                                                            ResultText := copystr(XmlNodeLevel6.AsXmlElement().InnerText, 1, MaxStrLen(ResultText));
                                                            LineAmount := ParseXmlDecimal(ResultText);
                                                            EVKOmnivaLines."Line Amount" := LineAmount;
                                                        end;

                                                    end;
                                                end;
                                            end;
                                        end;
                                        if NodeName = 'Description' then begin
                                            ResultText := copystr(XmlNodeLevel4.AsXmlElement().InnerText, 1, MaxStrLen(ResultText));
                                            Description1 := COPYSTR(ResultText, 1, 50);
                                            Description2 := COPYSTR(ResultText, 50, 50);
                                            EVKOmnivaLines."Description 1" := Description1;
                                            EVKOmnivaLines."Description 2" := Description2;
                                        end;
                                        if NodeName = 'ItemReserve' then begin
                                            ItemReserveList := XmlNodeLevel4.AsXmlElement().GetChildElements();
                                            InvoiceAttributes := XmlNodeLevel4.AsXmlElement().Attributes();
                                            for n := 0 TO InvoiceAttributes.Count - 1 DO begin
                                                InvoiceAttributes.Get(n + 1, CurrentXmlAttribute);
                                                NodeName := CurrentXmlAttribute.Name;
                                                if NodeName = 'extensionId' then begin
                                                    NodeName := '';
                                                    ResultText := copystr(CurrentXmlAttribute.Value, 1, MaxStrLen(ResultText));
                                                    if ResultText = 'eakVatCode' then begin
                                                        NodeName := '';
                                                        for o := 0 TO ItemReserveList.Count - 1 DO begin
                                                            ItemReserveList.Get(o + 1, XmlNodeLevel5);
                                                            NodeName := XmlNodeLevel5.AsXmlElement().Name;
                                                            if NodeName = 'InformationContent' then begin
                                                                NodeName := '';
                                                                EVKOmnivaLines."VAT Code" := copystr(XmlNodeLevel5.AsXmlElement().InnerText, 1, MaxStrLen(EVKOmnivaLines."VAT Code"));
                                                            end;
                                                        end;
                                                    end;
                                                    if ResultText = 'eakCostObjectives' then begin
                                                        NodeName := '';
                                                        for o := 0 TO ItemReserveList.Count - 1 DO begin
                                                            ItemReserveList.Get(o + 1, XmlNodeLevel5);
                                                            NodeName := XmlNodeLevel5.AsXmlElement().Name;
                                                            if NodeName = 'CustomContent' then begin
                                                                NodeName := '';
                                                                CustomContentList := XmlNodeLevel5.AsXmlElement().GetChildElements();
                                                                for p := 0 TO CustomContentList.Count - 1 DO begin
                                                                    CustomContentList.Get(p + 1, XmlNodeLevel6);
                                                                    NodeName := XmlNodeLevel6.AsXmlElement().Name;
                                                                    if NodeName = 'CostObjectives' then begin
                                                                        NodeName := '';
                                                                        CostObjectivesList := XmlNodeLevel6.AsXmlElement().GetChildElements();
                                                                        for l := 0 TO CostObjectivesList.Count - 1 DO begin
                                                                            CostObjectivesList.Get(l + 1, XmlNodeLevel7);
                                                                            NodeName := XmlNodeLevel7.AsXmlElement().Name;
                                                                            if NodeName = 'CostObjective' then begin
                                                                                NodeName := '';
                                                                                NodeName := '';

                                                                                InvoiceAttributes := XmlNodeLevel7.AsXmlElement().Attributes();
                                                                                for q := 0 TO InvoiceAttributes.Count - 1 DO begin
                                                                                    InvoiceAttributes.Get(q + 1, CurrentXmlAttribute);
                                                                                    NodeName := CurrentXmlAttribute.Name;
                                                                                    if NodeName = 'dimension' then begin
                                                                                        ResultText := copystr(CurrentXmlAttribute.Value, 1, MaxStrLen(ResultText));
                                                                                        DimensionCode := copystr(ResultText, 1, MaxStrLen(DimensionCode));
                                                                                        //DimensionValueCode := copystr(XmlNodeLevel5.AsXmlElement().InnerText, 1, MaxStrLen(DimensionValueCode));
                                                                                        DimensionValueCode := copystr(XmlNodeLevel7.AsXmlElement().InnerText, 1, MaxStrLen(DimensionValueCode));
                                                                                        if DimensionCode <> '' then begin
                                                                                            DimensionRowID := 1;
                                                                                            Clear(EVKOmnivaDimensions);
                                                                                            EVKOmnivaDimensions.Reset();
                                                                                            EVKOmnivaDimensions.SetRange("Header ID", EVKOmnivaHeader.id);
                                                                                            EVKOmnivaDimensions.SetRange("Line ID", EVKOmnivaLines.id);
                                                                                            if EVKOmnivaDimensions.FINDLAST() then DimensionRowID := EVKOmnivaDimensions.id + 1;
                                                                                            Clear(EVKOmnivaDimensions);
                                                                                            EVKOmnivaDimensions.Reset();
                                                                                            EVKOmnivaDimensions.INIT();
                                                                                            EVKOmnivaDimensions."Header ID" := EVKOmnivaHeader.id;
                                                                                            EVKOmnivaDimensions."Line ID" := EVKOmnivaLines.id;
                                                                                            EVKOmnivaDimensions.id := DimensionRowID;
                                                                                            if DimensionCode = 'VK_PROJEKTAI' then
                                                                                                DimensionCode := 'VK PROJEKTAI';

                                                                                            if DimensionCode = 'PROJEKTAS' then DimensionCode := 'PRODUKTAS';

                                                                                            EVKOmnivaDimensions."Dimension Code" := DimensionCode;
                                                                                            EVKOmnivaDimensions."Dimension Name" := DimensionValueCode;
                                                                                            EVKOmnivaDimensions.INSERT();
                                                                                        end;
                                                                                    end;
                                                                                end;
                                                                            end;
                                                                        end;
                                                                    end;
                                                                end;
                                                            end;
                                                        end;
                                                    end;
                                                end
                                            end;
                                        end;
                                        if NodeName = 'ItemDetailInfo' then begin
                                            NodeName := '';
                                            ItemDetailInfoList := XmlNodeLevel4.AsXmlElement().GetChildElements();
                                            for n := 0 TO ItemDetailInfoList.Count - 1 DO begin
                                                ItemDetailInfoList.Get(n + 1, XmlNodeLevel5);
                                                NodeName := XmlNodeLevel5.AsXmlElement().Name;
                                                if NodeName = 'ItemUnit' then begin
                                                    UnitOfMeasureCode := copystr(XmlNodeLevel5.AsXmlElement().InnerText, 1, MaxStrLen(UnitOfMeasureCode));
                                                    UnitOfMeasureCode := DELCHR(UnitOfMeasureCode, '=', '.');
                                                    EVKOmnivaLines."Unit of Measure" := UnitOfMeasureCode;
                                                end;
                                                if NodeName = 'ItemAmount' then begin
                                                    ResultText := copystr(XmlNodeLevel5.AsXmlElement().InnerText, 1, MaxStrLen(ResultText));
                                                    ItemQuantity := ParseXmlDecimal(ResultText);
                                                    EVKOmnivaLines.Quantity := ItemQuantity;

                                                end;
                                                if NodeName = 'ItemPrice' then begin
                                                    ResultText := copystr(XmlNodeLevel5.AsXmlElement().InnerText, 1, MaxStrLen(ResultText));
                                                    ItemPrice := ParseXmlDecimal(ResultText);
                                                    EVKOmnivaLines."Item Price" := ItemPrice;
                                                end;
                                            end;
                                        end;
                                    end;
                                    EVKOmnivaLines.Insert();



                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;
        InvoiceAttributes := BuyInvoicesResponseNode.AsXmlElement().Attributes();
        IncludesLatest := '';
        LatestChange := '';
        for i := 0 TO InvoiceAttributes.Count - 1 DO begin
            InvoiceAttributes.Get(i + 1, CurrentXmlAttribute);
            NodeName := CurrentXmlAttribute.Name;
            if NodeName = 'IncludesLatest' then
                IncludesLatest := copystr(CurrentXmlAttribute.Value, 1, MaxStrLen(IncludesLatest));
            if NodeName = 'LatestChange' then
                LatestChange := copystr(CurrentXmlAttribute.Value, 1, MaxStrLen(LatestChange));
        end;
        if LowerCase(IncludesLatest) = 'no' then
            ImportPurchaseInvoiceToTable(LatestChange, EVKOmnivaHeader, EVKOmnivaLines, EVKOmnivaDimensions)
        else begin
            EVKOmnivaSetup."Last Import Time" := LatestChange;
            EVKOmnivaSetup.MODifY();
        end;

    end;


    procedure OmnivaInvoiceImport(ImportFromDateTimeText: Text[30])
    var
        TempEVKOmnivaHeader: Record "EVK Omniva Header" temporary;
        TempEVKOmnivaLines: Record "EVK Omniva Lines" temporary;
        TempEVKOmnivaDimensions: Record "EVK Omniva Dimensions" temporary;
        LineFeedCharacter: char;
        MessageText: text;
        ProformaInvoiceMessage: text[200];
        ErrorMessage: text[200];
        TotalInvoiceCount: integer;
        CreatedInvoiceCount: integer;
    begin
        EVKOmnivaSetup.get();
        EVKOmnivaSetup.testfield("No. Series");
        LineFeedCharacter := 10;
        MessageText := '';
        ErrorMessage := '';
        ProformaInvoiceMessage := '';
        TotalInvoiceCount := 0;
        CreatedInvoiceCount := 0;

        if ImportFromDateTimeText = '' then begin
            clear(EVKOmnivaSetup);
            EVKOmnivaSetup.reset();
            EVKOmnivaSetup.get();
            if (EVKOmnivaSetup."Last Import Time" <> '') then
                ImportFromDateTimeText := EVKOmnivaSetup."Last Import Time"
            else
                ImportFromDateTimeText := FORMAT(WORKDATE(), 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00:00';
        end;
        ImportPurchaseInvoiceToTable(ImportFromDateTimeText, TempEVKOmnivaHeader, TempEVKOmnivaLines, TempEVKOmnivaDimensions);
        CheckPurchaseInvoiceImport(ErrorMessage, TempEVKOmnivaHeader, TempEVKOmnivaLines, TempEVKOmnivaDimensions);
        CreatePurchaseInvoice(ProformaInvoiceMessage, TempEVKOmnivaHeader, TempEVKOmnivaLines, TempEVKOmnivaDimensions, TotalInvoiceCount, CreatedInvoiceCount);


        if GUIALLOWED then begin
            if ErrorMessage <> '' then
                ErrorMessage := ';' + FORMAT(LineFeedCharacter) + 'Yra klaidų (žiūr. log informaciją)!';
            if ProformaInvoiceMessage <> '' then
                ProformaInvoiceMessage := ';' + FORMAT(LineFeedCharacter) + 'Yra išanskt. sąskaita (žiūr. log informaciją)!';

            MessageText := 'Viso SF (su kred) ' + FORMAT(TotalInvoiceCount) + ', pavyko sukurti ' + FORMAT(CreatedInvoiceCount) + ErrorMessage + ProformaInvoiceMessage;
            MESSAGE(MessageText);
        end;

    end;

    procedure CreatePurchaseInvoice(VAR ProformaInvoiceMessage: Text[200]; VAR EVKOmnivaHeader: Record "EVK Omniva Header" TEMPORARY; VAR EVKOmnivaLines: Record "EVK Omniva Lines" TEMPORARY; VAR EVKOmnivaDimensions: Record "EVK Omniva Dimensions" TEMPORARY; var TotalInvoiceCount: integer; var CreatedInvoiceCount: integer)
    var
        TempPurchLine: Record "Purchase Line" temporary;
        TotalPurchLine: Record "Purchase Line";
        TotalPurchLineLCY: Record "Purchase Line";
        PurchLine: Record "Purchase Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        GeneralLedgerSetupRecord: Record "General Ledger Setup";

        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        UnitofMeasure: Record "Unit of Measure";

        PurchasePost: Codeunit "Purch.-Post";

        NoSeries: Codeunit "No. Series";
        ReleasePurchaseDocument: codeunit "Release Purchase Document";
        ShortcutDimensionCodes: Array[8] of code[20];
        ErrorMessage: text[200];
        LogMessage: text[200];
        UnitOfMeasureMessage: text[200];
        VATAmountText: Text[30];


        PurchaseInvoiceNoSeries: code[20];
        HeaderDepartmentCode: code[20];
        ReasonCode: code[10];
        LineItemNo: code[20];
        HeaderDepartmentIsConsistent: boolean;
        UseReasonCode: boolean;
        AllLinesAreGLAccounts: boolean;
        UseSpecificGLAccount: boolean;
        UseSpecificAutopost: boolean;
        DepartmentCount: integer;
        LineNo: integer;
        ShortcutDimensionNo: integer;
        i: integer;
        VATAmount: Decimal;
        VATDifference: Decimal;
        CalculatedLinesTotal: Decimal;
        InvoiceLinesTotal: Decimal;

        PurchaseLineType: Enum "Purchase Line Type";

        step: integer;
        DocumentDate: date;
    begin

        EVKOmnivaSetup.get();
        GeneralLedgerSetup.Get();

        ShortcutDimensionCodes[1] := GeneralLedgerSetup."Shortcut Dimension 1 Code";
        ShortcutDimensionCodes[2] := GeneralLedgerSetup."Shortcut Dimension 2 Code";
        ShortcutDimensionCodes[3] := GeneralLedgerSetup."Shortcut Dimension 3 Code";
        ShortcutDimensionCodes[4] := GeneralLedgerSetup."Shortcut Dimension 4 Code";
        ShortcutDimensionCodes[5] := GeneralLedgerSetup."Shortcut Dimension 5 Code";
        ShortcutDimensionCodes[6] := GeneralLedgerSetup."Shortcut Dimension 6 Code";
        ShortcutDimensionCodes[7] := GeneralLedgerSetup."Shortcut Dimension 7 Code";
        ShortcutDimensionCodes[8] := GeneralLedgerSetup."Shortcut Dimension 8 Code";
        Clear(EVKOmnivaHeader);
        EVKOmnivaHeader.Reset();

        EVKOmnivaHeader.SetFilter("Assigned No.", '%1|%2', '', 'pakartot');

        TotalInvoiceCount := EVKOmnivaHeader.COUNT;
        if EVKOmnivaHeader.FINDset() then
            repeat
                if EVKOmnivaHeader."SF Label" = '0002' then begin //išankstinė sąskaitai
                    SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Vendor ' + EVKOmnivaHeader."Vendor Company Code" + ' tai išankstinė sąskaita', ErrorMessage);
                    ProformaInvoiceMessage := ErrorMessage;
                    PerduotiSFNR('Išankstinė', EVKOmnivaHeader."Omniva SF ID", false);
                end
                else
                    if EVKOmnivaHeader."Vendor No." <> '' then begin
                        Clear(PurchaseHeader);
                        PurchaseHeader.Reset();
                        PurchaseHeader.INIT();
                        case EVKOmnivaHeader."Invoice Type" of
                            'DEB':
                                PurchaseHeader.VALIDATE("Document Type", PurchaseHeader."Document Type"::Invoice);
                            'CRE':
                                PurchaseHeader.VALIDATE("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
                            else
                                error(WrongDocumentTypeErr);
                        end;



                        PurchaseHeader."No." := '';
                        PurchaseInvoiceNoSeries := EVKOmnivaSetup."No. Series";
                        PurchaseHeader."No. Series" := PurchaseInvoiceNoSeries;
                        PurchaseHeader."No." := NoSeries.GetNextNo(PurchaseInvoiceNoSeries, WorkDate());
                        PurchaseHeader.INSERT(true);
                        CreatedInvoiceCount += 1;
                        PurchaseHeader.VALIDATE("Posting Date", EVKOmnivaHeader."Posting Date");
                        PurchaseHeader.VALIDATE("Buy-from Vendor No.", EVKOmnivaHeader."Vendor No.");
                        PurchaseHeader.VALIDATE("Document Date", EVKOmnivaHeader."Posting Date");
                        PurchaseHeader."Omniva Date" := WORKDATE();
                        if (EVKOmnivaHeader."Invoice Type" = 'CRE') then begin
                            PurchaseHeader.VALIDATE("Vendor Cr. Memo No.", EVKOmnivaHeader."Vendor Invoice No.");
                            PurchaseHeader.VALIDATE("Vendor Authorization No.", EVKOmnivaHeader."Vendor Invoice No.");
                        end
                        else
                            PurchaseHeader.VALIDATE("Vendor Invoice No.", EVKOmnivaHeader."Vendor Invoice No.");

                        if EVKOmnivaHeader."Currency Code" <> '' then
                            PurchaseHeader.VALIDATE("Currency Code", EVKOmnivaHeader."Currency Code");

                        if EVKOmnivaHeader."SF Label" = '0001' then  //avansinė                                                                            
                            PurchaseHeader.VALIDATE("Bal. Account Type", PurchaseHeader."Bal. Account Type"::"Bank Account");

                        if (EVKOmnivaHeader."Applies-to Doc. No." <> '') AND (EVKOmnivaHeader."Invoice Type" = 'CRE') then begin
                            PurchaseHeader.VALIDATE("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
                            PurchaseHeader.VALIDATE("Applies-to Doc. No.", EVKOmnivaHeader."Applies-to Doc. No.");
                        end;

                        InsertAdditionalInfo(EVKOmnivaHeader, PurchaseHeader);//event
                        PurchaseHeader.VALIDATE("Posting No.", PurchaseHeader."No.");
                        PurchaseHeader.MODifY(true);

                        Clear(EVKOmnivaDimensions);
                        EVKOmnivaDimensions.Reset();
                        EVKOmnivaDimensions.SetRange("Header ID", EVKOmnivaHeader.id);
                        EVKOmnivaDimensions.SetRange("Dimension Code", 'PADALINYS');
                        HeaderDepartmentIsConsistent := true;
                        HeaderDepartmentCode := '';
                        DepartmentCount := 1;
                        if EVKOmnivaDimensions.FINDset() then
                            repeat
                                if DepartmentCount = 1 then begin
                                    HeaderDepartmentCode := EVKOmnivaDimensions."Dimension Name";
                                    DepartmentCount := 2;
                                end
                                else
                                    if EVKOmnivaDimensions."Dimension Name" <> HeaderDepartmentCode then
                                        HeaderDepartmentIsConsistent := false;
                            until EVKOmnivaDimensions.next() = 0;
                        if (HeaderDepartmentIsConsistent) AND (HeaderDepartmentCode <> '') then begin
                            PurchaseHeader.VALIDATE("Shortcut Dimension 1 Code", HeaderDepartmentCode);
                            PurchaseHeader.MODifY(true);
                        end;
                        Clear(EVKOmnivaLines);
                        EVKOmnivaLines.Reset();
                        EVKOmnivaLines.SetRange("Header ID", EVKOmnivaHeader.id);
                        LineNo := 10000;
                        if EVKOmnivaLines.FINDset() then
                            repeat
                                Clear(PurchaseLine);
                                PurchaseLine.Reset();
                                PurchaseLine.INIT();
                                PurchaseLine.VALIDATE("Document Type", PurchaseHeader."Document Type");
                                PurchaseLine.VALIDATE("Document No.", PurchaseHeader."No.");
                                PurchaseLine.VALIDATE("Line No.", LineNo);
                                PurchaseLine.INSERT(true);
                                LineNo += 10000;
                                PurchaseLine.VALIDATE(Type, PurchaseLine.Type::"G/L Account");
                                PurchaseLine.VALIDATE("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");

                                UseSpecificGLAccount := false;
                                InsertPurchaseLineNo(EVKOmnivaLines, PurchaseLine, UseSpecificGLAccount);

                                if not UseSpecificGLAccount then begin
                                    Clear(GLAccount);
                                    GLAccount.Reset();
                                    GLAccount.SetRange("No.", EVKOmnivaLines."G/L Account Code");
                                    GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
                                    if GLAccount.FINDFIRST() then
                                        PurchaseLine.VALIDATE("No.", EVKOmnivaLines."G/L Account Code")
                                    else begin
                                        GLAccount.SetRange("Account Type");
                                        if GLAccount.FINDFIRST() then
                                            PurchaseLine."No." := EVKOmnivaLines."G/L Account Code";
                                    end;
                                end;
                                if EVKOmnivaLines."Item No." <> '' then begin
                                    Clear(Item);
                                    Item.Reset();
                                    Item.SetRange("No.", EVKOmnivaLines."Item No.");
                                    Item.SetRange(Blocked, false);
                                    if Item.FINDFIRST() then begin
                                        PurchaseLine.VALIDATE(Type, PurchaseLine.Type::Item);
                                        PurchaseLine.VALIDATE("No.", EVKOmnivaLines."Item No.");
                                    end;
                                end;
                                PurchaseLine.MODifY(true);
                                InsertPurchaseLineAdditionalInfo(EVKOmnivaHeader, PurchaseLine);//event

                                if EVKOmnivaLines."Unit of Measure" <> '' then begin
                                    if PurchaseLine.Type = PurchaseLine.Type::Item then begin
                                        clear(ItemUnitofMeasure);
                                        ItemUnitofMeasure.Reset();
                                        ItemUnitofMeasure.SetRange(Code, EVKOmnivaLines."Unit of Measure");
                                        UnitOfMeasureMessage := 'Tiekėjas: ' + PurchaseHeader."Buy-from Vendor No.";
                                        if ItemUnitofMeasure.IsEmpty then
                                            SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Blogas prekės matavimo UnitOfMeasureCode: ' + EVKOmnivaLines."Unit of Measure", UnitOfMeasureMessage);
                                    end
                                    else begin
                                        clear(UnitofMeasure);
                                        UnitofMeasure.Reset();
                                        UnitofMeasure.SetRange(Code, EVKOmnivaLines."Unit of Measure");
                                        UnitOfMeasureMessage := 'Tiekėjas: ' + PurchaseHeader."Buy-from Vendor No.";
                                        if UnitofMeasure.IsEmpty then
                                            SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Blogas dk matavimo UnitOfMeasureCode: ' + EVKOmnivaLines."Unit of Measure", UnitOfMeasureMessage);
                                    end;
                                    PurchaseLine.VALIDATE("Unit of Measure Code", EVKOmnivaLines."Unit of Measure");
                                end
                                else
                                    PurchaseLine.VALIDATE("Unit of Measure Code", 'VNT');
                                if EVKOmnivaHeader."Invoice Type" = 'CRE' then begin
                                    if EVKOmnivaLines.Quantity = 0 then EVKOmnivaLines.Quantity := -1;
                                    PurchaseLine.VALIDATE(Quantity, ABS(EVKOmnivaLines.Quantity));
                                end
                                else begin
                                    if EVKOmnivaLines.Quantity = 0 then EVKOmnivaLines.Quantity := 1;
                                    PurchaseLine.VALIDATE(Quantity, EVKOmnivaLines.Quantity);
                                end;
                                if EVKOmnivaLines."Item Price" <> 0 then
                                    PurchaseLine.VALIDATE("Direct Unit Cost", EVKOmnivaLines."Item Price");
                                if EVKOmnivaLines."Line Amount" <> 0 then
                                    if EVKOmnivaLines.Quantity <> 0 then
                                        if EVKOmnivaHeader."Invoice Type" = 'CRE' then
                                            PurchaseLine.VALIDATE("Direct Unit Cost", ABS(EVKOmnivaLines."Line Amount" / EVKOmnivaLines.Quantity))
                                        else
                                            PurchaseLine.VALIDATE("Direct Unit Cost", EVKOmnivaLines."Line Amount" / EVKOmnivaLines.Quantity);
                                PurchaseLine.VALIDATE(Description, EVKOmnivaLines."Description 1");
                                PurchaseLine.VALIDATE("Description 2", EVKOmnivaLines."Description 2");
                                PurchaseLine.MODifY(true);
                                Clear(EVKOmnivaDimensions);
                                EVKOmnivaDimensions.Reset();
                                EVKOmnivaDimensions.SetRange("Header ID", EVKOmnivaHeader.id);
                                EVKOmnivaDimensions.SetRange("Line ID", EVKOmnivaLines.id);
                                if EVKOmnivaDimensions.FINDset() then
                                    repeat
                                        case EVKOmnivaDimensions."Dimension Code" of
                                            'SANDELIS':
                                                PurchaseLine."Location Code" := copystr(EVKOmnivaDimensions."Dimension Name", 1, MaxStrLen(PurchaseLine."Location Code"));
                                            'INVESTICIJOS_2018':
                                                begin
                                                    Clear(DimensionValue);
                                                    DimensionValue.Reset();
                                                    DimensionValue.SetRange("Dimension Code", EVKOmnivaDimensions."Dimension Code");
                                                    DimensionValue.SetRange(Code, EVKOmnivaDimensions."Dimension Name");
                                                    DimensionValue.SetRange(Blocked, false);
                                                    if DimensionValue.FINDFIRST() then begin
                                                        EVKOmnivaSetup.get();
                                                        EVKOmnivaSetup.get();
                                                        EVKOmnivaSetup.get();
                                                    end;
                                                end;
                                            else begin
                                                ShortcutDimensionNo := 0;
                                                FOR i := 1 TO 8 DO
                                                    if ShortcutDimensionCodes[i] = EVKOmnivaDimensions."Dimension Code" then
                                                        ShortcutDimensionNo := i;
                                                if ShortcutDimensionNo > 0 then begin
                                                    //reikia patikrinti dimensiją
                                                    Clear(DimensionValue);
                                                    DimensionValue.Reset();
                                                    DimensionValue.SetRange("Dimension Code", EVKOmnivaDimensions."Dimension Code");
                                                    DimensionValue.SetRange(Code, EVKOmnivaDimensions."Dimension Name");
                                                    DimensionValue.SetRange(Blocked, false);
                                                    if DimensionValue.FINDFIRST() then begin
                                                        PurchaseLine.ValidateShortcutDimCode(ShortcutDimensionNo, EVKOmnivaDimensions."Dimension Name");
                                                        if EVKOmnivaDimensions."Dimension Code" = ShortcutDimensionCodes[1] then
                                                            PurchaseLine.VALIDATE("Shortcut Dimension 1 Code", EVKOmnivaDimensions."Dimension Name");
                                                        if EVKOmnivaDimensions."Dimension Code" = ShortcutDimensionCodes[2] then
                                                            PurchaseLine.VALIDATE("Shortcut Dimension 2 Code", EVKOmnivaDimensions."Dimension Name");
                                                    end;
                                                end;
                                            end;
                                        end;
                                    until EVKOmnivaDimensions.next() = 0;
                                PurchaseLine.MODifY();
                            until EVKOmnivaLines.next() = 0;
                        EVKOmnivaHeader."Purchase SF No." := PurchaseHeader."No.";
                        PurchaseHeader.MODifY();
                        Clear(PurchaseLine);
                        PurchaseLine.Reset();
                        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                        if PurchaseLine.COUNT > 0 then begin
                            PurchaseLineType := Enum::"Purchase Line Type"::" ";
                            LineItemNo := '';

                            ReasonCode := '';
                            UseReasonCode := true;
                            step := 0;
                            AllLinesAreGLAccounts := true;
                            if PurchaseLine.FINDset() then
                                repeat

                                    if step = 0 then begin
                                        PurchaseLineType := PurchaseLine.Type;
                                        LineItemNo := PurchaseLine."No.";
                                        step := 1;
                                    end;
                                    EventReassonCode(ReasonCode, UseReasonCode, PurchaseLine);//event

                                    if PurchaseLineType <> PurchaseLine.Type then
                                        UseReasonCode := false;

                                    if LineItemNo <> PurchaseLine."No." then
                                        UseReasonCode := false;

                                until EVKOmnivaLines.next() = 0;
                            if (UseReasonCode) AND (ReasonCode <> '') then begin
                                PurchaseHeader."Reason Code" := ReasonCode;
                                PurchaseHeader.MODifY();
                            end
                            else
                                if (NOT UseReasonCode) AND (AllLinesAreGLAccounts) then begin
                                    Clear(PurchaseLine);
                                    PurchaseLine.Reset();
                                    PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                                    PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                                    step := 0;
                                    ReasonCode := '';
                                    if PurchaseLine.FINDset() then
                                        repeat
                                            if step = 0 then begin
                                                step := 1;
                                                if PurchaseLine.Type = PurchaseLine.Type::"G/L Account" then begin
                                                    if PurchaseLine."No." <> '' then begin
                                                        Clear(GLAccount);
                                                        GLAccount.Reset();
                                                        GLAccount.SetRange("No.", PurchaseLine."No.");
                                                    end
                                                    else
                                                        AllLinesAreGLAccounts := false;
                                                end
                                                else
                                                    AllLinesAreGLAccounts := false;
                                            end
                                            else
                                                if PurchaseLine.Type = PurchaseLine.Type::"G/L Account" then begin
                                                    if PurchaseLine."No." <> '' then begin
                                                        Clear(GLAccount);
                                                        GLAccount.Reset();
                                                        GLAccount.SetRange("No.", PurchaseLine."No.");

                                                    end
                                                    else
                                                        AllLinesAreGLAccounts := false;
                                                end
                                                else
                                                    AllLinesAreGLAccounts := false;
                                        until PurchaseLine.next() = 0;
                                    if (AllLinesAreGLAccounts) AND (ReasonCode <> '') then begin
                                        PurchaseHeader."Reason Code" := ReasonCode;
                                        PurchaseHeader.MODifY();
                                    end
                                end;

                        end;

                        if EVKOmnivaHeader."Total VAT Sum" > 0 then begin
                            Clear(TempPurchLine);
                            TempPurchLine.Reset();
                            PurchasePost.GetPurchLines(PurchaseHeader, TempPurchLine, 0);
                            Clear(PurchasePost);
                            PurchasePost.SumPurchLinesTemp(PurchaseHeader, TempPurchLine, 0, TotalPurchLine, TotalPurchLineLCY, VATAmount, VATAmountText);
                            if EVKOmnivaHeader."Total VAT Sum" <> VATAmount then begin
                                VATDifference := Abs(EVKOmnivaHeader."Total VAT Sum" - VATAmount);
                                GeneralLedgerSetupRecord.Get();
                                if VATDifference < GeneralLedgerSetupRecord."Max. VAT Difference Allowed" then begin
                                    PurchLine.CalcVATAmountLines(0, PurchaseHeader, TempPurchLine, TempVATAmountLine);
                                    if TempVATAmountLine.Count = 1 then begin
                                        TempVATAmountLine.Validate("VAT Amount", EVKOmnivaHeader."Total VAT Sum");
                                        TempVATAmountLine.Modify(true);

                                        if TempVATAmountLine.GetAnyLineModified() then begin
                                            clear(PurchLine);
                                            PurchLine.Reset();
                                            PurchLine.UpdateVATOnLines(0, PurchaseHeader, PurchLine, TempVATAmountLine);
                                            PurchLine.UpdateVATOnLines(1, PurchaseHeader, PurchLine, TempVATAmountLine);
                                        end;
                                    end;
                                end;
                            end;
                        end;
                        PerduotiSFNR(PurchaseHeader."No.", EVKOmnivaHeader."Omniva SF ID", false);
                        COMMIT();
                        //Auto posting>>
                        SFlog(PurchaseHeader."Vendor Invoice No.", 'Autopost 1', LogMessage);
                        if EVKOmnivaSetup."Omniva Autopost" then begin
                            SFlog(PurchaseHeader."Vendor Invoice No.", 'Autopost 2', LogMessage);
                            UseSpecificAutopost := false;
                            //AutomatingPosting(EVKOmnivaHeader, EVKOmnivaLines, PurchaseHeader, UseSpecificAutopost); 20231211 eja nebereikalingas
                            if not UseSpecificAutopost then begin
                                SFlog(PurchaseHeader."Vendor Invoice No.", 'Autopost 3', LogMessage);
                                SFlog(PurchaseHeader."Vendor Invoice No.", 'PMC: ' + PurchaseHeader."Payment Method Code", LogMessage);
                                if (PurchaseHeader."Payment Method Code" = 'AUTOMAT') then begin
                                    SFlog(PurchaseHeader."Vendor Invoice No.", 'Autopost 4', LogMessage);
                                    CalculatedLinesTotal := 0;
                                    InvoiceLinesTotal := 0;
                                    Clear(EVKOmnivaLines);
                                    EVKOmnivaLines.Reset();
                                    EVKOmnivaLines.SetRange("Header ID", EVKOmnivaHeader.id);
                                    if EVKOmnivaLines.FINDset() then
                                        repeat
                                            CalculatedLinesTotal += EVKOmnivaLines."Line Amount";
                                        until EVKOmnivaLines.Next() = 0;
                                    Clear(PurchaseLine);
                                    PurchaseLine.Reset();
                                    PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                                    PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                                    if PurchaseLine.FINDset() then
                                        repeat
                                            InvoiceLinesTotal += PurchaseLine."Line Amount";
                                        until PurchaseLine.Next() = 0;
                                    SFlog(PurchaseHeader."Vendor Invoice No.", 'Autopost 5:' + format(CalculatedLinesTotal) + '===' + format(InvoiceLinesTotal), LogMessage);
                                    if (CalculatedLinesTotal > 0) AND (CalculatedLinesTotal = InvoiceLinesTotal) then begin
                                        SFlog(PurchaseHeader."Vendor Invoice No.", 'Autopost 6', LogMessage);
                                        Clear(GeneralLedgerSetup);
                                        GeneralLedgerSetup.Reset();
                                        GeneralLedgerSetup.Get();

                                        if PurchaseHeader."Posting Date" < GeneralLedgerSetup."Allow Posting From" then begin
                                            DocumentDate := PurchaseHeader."Document Date";
                                            PurchaseHeader.VALIDATE("Posting Date", GeneralLedgerSetup."Allow Posting From");
                                            PurchaseHeader.VALIDATE("Document Date", DocumentDate);
                                        end;
                                        PurchaseHeader."Omniva Autopost" := true;
                                        PurchaseHeader.MODifY(true);
                                        SFlog(PurchaseHeader."Vendor Invoice No.", 'Autopost 7', LogMessage);
                                        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);
                                        SFlog(PurchaseHeader."Vendor Invoice No.", 'Autopost 8', LogMessage);
                                    end;
                                end
                            end;
                        end;
                        //Auto posting <<
                    end;
            until EVKOmnivaHeader.Next() = 0;

    end;

    procedure PerduotiSFNR(BusinessCentralDocumentNo: Code[20]; OmnivaInvoiceId: Code[20]; ChangeCompany: Boolean)
    var
        ResponseText: Text;
    begin
        OmnivaAuthorization();
        XmlRequestText := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
        XmlRequestText += 'xmlns:erp="http://e-arvetekeskus.eu/erp">';
        XmlRequestText += '<soapenv:Header/>';
        XmlRequestText += '<soapenv:Body>';
        XmlRequestText += '<erp:BuyInvoiceRegisteredRequest authPhrase="' + AuthorizationToken + '">';
        XmlRequestText += '<erp:RegisteredInvoice invoiceId="' + OmnivaInvoiceId + '">';
        XmlRequestText += '<erp:ErpDocumentNumber>' + BusinessCentralDocumentNo + '</erp:ErpDocumentNumber>';
        XmlRequestText += '</erp:RegisteredInvoice>';
        XmlRequestText += '</erp:BuyInvoiceRegisteredRequest>';
        XmlRequestText += '</soapenv:Body>';
        XmlRequestText += '</soapenv:Envelope>';

        OmnivaApiClient.SendRequest(XmlRequestText, ServiceUrl, false, false, ResponseText);

        if not XmlDocument.ReadFrom(ResponseText, DocXmlDocument) then
            Error(InvalidXmlResponseErr);

        if EVKOmnivaSetup."Download File" then
            OmnivaApiClient.ExportDiagnosticFile(ResponseText, 'confirm.xml', false);

    end;

    procedure CheckPurchaseInvoiceImport(VAR ErrorMessage: Text[200]; VAR EVKOmnivaHeader: Record "EVK Omniva Header" TEMPORARY; VAR EVKOmnivaLines: Record "EVK Omniva Lines" TEMPORARY; VAR EVKOmnivaDimensions: Record "EVK Omniva Dimensions" TEMPORARY)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        Location: Record Location;
        VendorRecordRef: RecordRef;
        //VendorContrctRecordRef: RecordRef;
        NumberFieldRef: FieldRef;
        //VendorNoFieldRef: FieldRef;
        RegistrationNoFieldRef: FieldRef;
        BusinessCentralVendorNo: code[20];
        RegistrationFieldNo: Integer;
        VendorFound: boolean;
    begin
        Clear(EVKOmnivaHeader);
        EVKOmnivaHeader.Reset();

        EVKOmnivaHeader.SetFilter("Assigned No.", '%1|%2', '', 'pakartot');

        if EVKOmnivaHeader.FINDset() then
            repeat
                if EVKOmnivaHeader."SF Label" = '0002' then begin //išankstinei sąskaitai
                    EVKOmnivaHeader.Errors := true;
                    EVKOmnivaHeader.MODifY();
                    SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Tiekėjas ' + EVKOmnivaHeader."Vendor Company Code" + ' tai išankstinė sąskaita', ErrorMessage);
                end
                else begin
                    BusinessCentralVendorNo := '';
                    if EVKOmnivaHeader."Vendor Navision No." <> '' then
                        BusinessCentralVendorNo := EVKOmnivaHeader."Vendor Navision No."
                    else
                        if EVKOmnivaHeader."Vendor Company Code" <> '' then
                            BusinessCentralVendorNo := EVKOmnivaHeader."Vendor Company Code";
                    if BusinessCentralVendorNo = '' then begin
                        EVKOmnivaHeader.Errors := true;
                        EVKOmnivaHeader.MODifY();
                        SFlog(EVKOmnivaHeader."Vendor Company Code", 'Nenurodytas tiekėjas', ErrorMessage);
                    end
                    else begin
                        Clear(Vendor);
                        Vendor.Reset();
                        Vendor.SetRange("No.", BusinessCentralVendorNo);
                        VendorFound := false;
                        if Vendor.FINDFIRST() then begin
                            EVKOmnivaHeader."Vendor No." := Vendor."No.";
                            EVKOmnivaHeader.MODifY();
                            VendorFound := true;
                        end
                        else begin
                            EVKOmnivaSetup.get();
                            EVKOmnivaSetup.get();
                            EVKOmnivaSetup.get();

                            EVKOmnivaSetup.get();
                            if EVKOmnivaSetup."Vendor Registration No. Field" > 0 then begin
                                RegistrationFieldNo := EVKOmnivaSetup."Vendor Registration No. Field";
                                VendorRecordRef.Close();
                                VendorRecordRef.Open(23);
                                RegistrationNoFieldRef := VendorRecordRef.FIELD(RegistrationFieldNo);
                                RegistrationNoFieldRef.SetRange(BusinessCentralVendorNo);
                                if VendorRecordRef.findfirst() then begin
                                    NumberFieldRef := VendorRecordRef.FIELD(1);
                                    EVKOmnivaHeader."Vendor No." := NumberFieldRef.Value;
                                    EVKOmnivaHeader.MODifY();
                                    VendorFound := true;
                                end;
                            end;


                            if not VendorFound then begin
                                Clear(Vendor);
                                Vendor.Reset();
                                Vendor.SETCURRENTKEY("VAT Registration No.");
                                Vendor.SetRange("VAT Registration No.", BusinessCentralVendorNo);
                                if Vendor.FINDFIRST() then begin
                                    EVKOmnivaHeader."Vendor No." := Vendor."No.";
                                    EVKOmnivaHeader.MODifY();
                                end
                                else begin
                                    EVKOmnivaHeader.Errors := true;
                                    EVKOmnivaHeader.MODifY();
                                    SFlog(EVKOmnivaHeader."Vendor Company Code", 'Tiekėjas ' + BusinessCentralVendorNo + ' nerastas', ErrorMessage);
                                end;
                            end;
                        end;
                    end;
                    if EVKOmnivaHeader."Invoice Type" = '' then begin
                        EVKOmnivaHeader.Errors := true;
                        EVKOmnivaHeader.MODifY();
                        SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Nenurodytas sf tipas: ' + EVKOmnivaHeader."Vendor Company Code", ErrorMessage);
                    end
                    else
                        if (EVKOmnivaHeader."Invoice Type" <> 'DEB') AND (EVKOmnivaHeader."Invoice Type" <> 'CRE') then begin
                            EVKOmnivaHeader.Errors := true;
                            EVKOmnivaHeader.MODifY();
                            SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Blogas sf tipas: ' + EVKOmnivaHeader."Invoice Type", ErrorMessage);
                        end;
                    if (EVKOmnivaHeader."Bank Account No." <> '') AND (EVKOmnivaHeader."Vendor No." <> '') then begin
                        Clear(VendorBankAccount);
                        VendorBankAccount.Reset();
                        VendorBankAccount.SetRange("Vendor No.", EVKOmnivaHeader."Vendor No.");
                        VendorBankAccount.SetRange("Bank Account No.", EVKOmnivaHeader."Bank Account No.");
                        if NOT VendorBankAccount.FINDFIRST() then begin
                            VendorBankAccount.SetRange("Bank Account No.");
                            VendorBankAccount.SetRange(IBAN, EVKOmnivaHeader."Bank Account No.");
                            if NOT VendorBankAccount.FINDFIRST() then begin
                                EVKOmnivaHeader.Errors := true;
                                EVKOmnivaHeader.MODifY();
                                SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Nerasta banko sąsk. ' + EVKOmnivaHeader."Bank Account No.", ErrorMessage);
                            end
                            else begin
                                EVKOmnivaHeader."Bank Code" := copystr(VendorBankAccount.Code, 1, MaxStrLen(EVKOmnivaHeader."Bank Code"));
                                EVKOmnivaHeader.MODifY();
                            end;
                        end
                        else begin
                            EVKOmnivaHeader."Bank Code" := copystr(VendorBankAccount.Code, 1, MaxStrLen(EVKOmnivaHeader."Bank Code"));
                            EVKOmnivaHeader.MODifY();
                        end;
                    end;
                    Clear(EVKOmnivaDimensions);
                    EVKOmnivaDimensions.Reset();
                    EVKOmnivaDimensions.SetRange("Header ID", EVKOmnivaHeader.id);
                    if EVKOmnivaDimensions.FINDset() then
                        repeat
                            case EVKOmnivaDimensions."Dimension Code" of
                                'SUTARTIS':
                                    begin
                                        if EVKOmnivaHeader."Contract No." = '' then begin
                                            EVKOmnivaHeader."Contract No." := EVKOmnivaDimensions."Dimension Name";
                                            EVKOmnivaHeader.MODifY();
                                        end;
                                        Clear(EVKOmnivaLines);
                                        EVKOmnivaLines.Reset();
                                        EVKOmnivaLines.SetRange("Header ID", EVKOmnivaHeader.id);
                                        EVKOmnivaLines.SetRange(ID, EVKOmnivaDimensions."Line ID");
                                        if EVKOmnivaLines.FINDFIRST() then begin
                                            EVKOmnivaLines."Contract No." := EVKOmnivaDimensions."Dimension Name";
                                            EVKOmnivaLines.MODifY();
                                        end;
                                        CheckIfVendorContractExist(EVKOmnivaHeader, EVKOmnivaDimensions);
                                    end;
                                'PREKE':
                                    begin
                                        Clear(EVKOmnivaLines);
                                        EVKOmnivaLines.Reset();
                                        EVKOmnivaLines.SetRange("Header ID", EVKOmnivaHeader.id);
                                        EVKOmnivaLines.SetRange(ID, EVKOmnivaDimensions."Line ID");
                                        if EVKOmnivaLines.FINDFIRST() then begin
                                            EVKOmnivaLines."Item No." := EVKOmnivaDimensions."Dimension Name";
                                            EVKOmnivaLines.MODifY();
                                        end;
                                    end;
                                'SANDELIS':
                                    begin
                                        Clear(Location);
                                        Location.Reset();
                                        Location.SetRange(Code, EVKOmnivaDimensions."Dimension Name");
                                        if Location.IsEmpty then begin
                                            EVKOmnivaHeader.Errors := true;
                                            EVKOmnivaHeader.MODifY();
                                            SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Blogas vietos kodas ' + EVKOmnivaDimensions."Dimension Code" + '->' + EVKOmnivaDimensions."Dimension Name", ErrorMessage);
                                        end;
                                    end;
                                else begin
                                    Clear(DimensionValue);
                                    DimensionValue.Reset();

                                    DimensionValue.SetRange("Dimension Code", EVKOmnivaDimensions."Dimension Code");

                                    DimensionValue.SetRange(Code, EVKOmnivaDimensions."Dimension Name");
                                    DimensionValue.SetRange(Blocked, false);
                                    if DimensionValue.IsEmpty then begin
                                        EVKOmnivaHeader.Errors := true;
                                        EVKOmnivaHeader.MODifY();
                                        SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Bloga dimensija ' + EVKOmnivaDimensions."Dimension Code" + '->' + EVKOmnivaDimensions."Dimension Name", ErrorMessage);
                                    end;
                                end;

                            end
                        until EVKOmnivaDimensions.Next() = 0;
                    Clear(EVKOmnivaLines);
                    EVKOmnivaLines.Reset();
                    EVKOmnivaLines.SetRange("Header ID", EVKOmnivaHeader.id);
                    if EVKOmnivaLines.FINDSET() then
                        repeat
                            if EVKOmnivaLines."G/L Account Code" = '' then begin
                                EVKOmnivaHeader.Errors := true;
                                EVKOmnivaHeader.MODifY();
                                SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Nenurodyka eilutės dk', ErrorMessage);
                            end
                            else begin
                                Clear(GLAccount);
                                GLAccount.Reset();
                                GLAccount.SetRange("No.", EVKOmnivaLines."G/L Account Code");

                                if GLAccount.IsEmpty then begin
                                    EVKOmnivaHeader.Errors := true;
                                    EVKOmnivaHeader.MODifY();
                                    SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Tokios dk naudoti negalima: ' + EVKOmnivaLines."G/L Account Code", ErrorMessage);
                                end;

                            end;
                            if EVKOmnivaLines."Item No." <> '' then begin
                                Clear(Item);
                                Item.Reset();
                                Item.SetRange("No.", EVKOmnivaLines."Item No.");
                                Item.SetRange(Blocked, false);
                                if Item.IsEmpty then begin
                                    EVKOmnivaHeader.Errors := true;
                                    EVKOmnivaHeader.MODifY();
                                    SFlog(EVKOmnivaHeader."Vendor Invoice No.", 'Tokios prekes naudoti negalima: ' + EVKOmnivaLines."Item No.", ErrorMessage);
                                end;
                            end;
                        until EVKOmnivaLines.Next() = 0;
                end;
            until EVKOmnivaHeader.Next() = 0;
    end;

    procedure ImportPurchaseInvoiceToTable(ImportFromDateTimeText: Text[30]; VAR EVKOmnivaHeader: Record "EVK Omniva Header" TEMPORARY; VAR EVKOmnivaLines: Record "EVK Omniva Lines" TEMPORARY; VAR EVKOmnivaDimensions: Record "EVK Omniva Dimensions" TEMPORARY)
    var
        ResponseText: Text;
    begin
        OmnivaAuthorization();
        XmlRequestText := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ';
        XmlRequestText += 'xmlns:erp="http://e-arvetekeskus.eu/erp">';
        XmlRequestText += '<soapenv:Header/>';
        XmlRequestText += '<soapenv:Body>';
        XmlRequestText += '<erp:BuyInvoiceRequest since="' + ImportFromDateTimeText + '" ';
        XmlRequestText += 'format="E_INV_LT_1_1" replace="NO" ';
        XmlRequestText += 'operator="NO" authPhrase="' + AuthorizationToken + '">';
        XmlRequestText += '<erp:state>VERifIED</erp:state>';
        XmlRequestText += '</erp:BuyInvoiceRequest>';
        XmlRequestText += '</soapenv:Body>';
        XmlRequestText += '</soapenv:Envelope>';

        OmnivaApiClient.SendRequest(
            XmlRequestText,
            ServiceUrl,
            false,
            EVKOmnivaSetup."Download File",
            ResponseText);

        if not XmlDocument.ReadFrom(ResponseText, DocXmlDocument) then
            Error(InvalidXmlResponseErr);

        OmnivaImportavimas(EVKOmnivaHeader, EVKOmnivaDimensions, EVKOmnivaLines);

    end;

    local procedure ParseXmlDate(XmlValue: Text): Date
    var
        ParsedDate: Date;
    begin
        if not Evaluate(ParsedDate, XmlValue, 9) then
            Error(InvalidXmlDateErr, XmlValue);

        exit(ParsedDate);
    end;

    local procedure ParseXmlDecimal(XmlValue: Text): Decimal
    var
        ParsedDecimal: Decimal;
    begin
        if not Evaluate(ParsedDecimal, XmlValue, 9) then
            Error(InvalidXmlDecimalErr, XmlValue);

        exit(ParsedDecimal);
    end;

    procedure PasalintiSimbolius(VendorInvoiceNo: Code[20]): Code[20]
    var
        SanitizedInvoiceNo: text[20];
        CharacterText: text[20];
        NewInvoiceNo: code[20];
        CurrentCharacter: char;
        i: integer;
    begin

        SanitizedInvoiceNo := '';
        NewInvoiceNo := '';
        FOR i := 1 TO STRLEN(VendorInvoiceNo) DO begin
            CurrentCharacter := VendorInvoiceNo[i];
            CharacterText := FORMAT(CurrentCharacter);
            CharacterText := UPPERCASE(CharacterText);
            if CharacterText IN ['Z', 'X', 'C', 'V', 'B', 'N', 'M', 'A', 'S', 'D', 'F', 'G', 'H',
            'J', 'K', 'L', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'À', 'È', 'Æ', 'Ë', 'Á', 'Ð', 'Ø', 'Û', 'Þ',
            'Ą', 'Č', 'Ę', 'Ė', 'Į', 'Š', 'Ų', 'Ū', 'Ž',
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'] then
                SanitizedInvoiceNo += CharacterText;

        end;
        NewInvoiceNo := SanitizedInvoiceNo;
        EXIT(NewInvoiceNo);
    end;

    procedure SFlog(VendorInvoiceNo: Code[35]; LogText: Text[250]; VAR ErrorMessage: Text[200])
    var
        EntryNo: Integer;
    begin
        ErrorMessage := 'taip';
        EntryNo := 1;
        Clear(EVKOmnivaLog);
        EVKOmnivaLog.Reset();
        EVKOmnivaLog.LockTable();
        if EVKOmnivaLog.FINDLAST() then
            EntryNo := EVKOmnivaLog."Entry No." + 1;
        if VendorInvoiceNo <> '' then begin
            Clear(EVKOmnivaLog);
            EVKOmnivaLog.Reset();
            EVKOmnivaLog.INIT();
            EVKOmnivaLog."Entry No." := EntryNo;
            EVKOmnivaLog."Vendor Invoice No." := VendorInvoiceNo;
            EVKOmnivaLog.Comment := LogText;
            EVKOmnivaLog."Record Date" := Today();
            EVKOmnivaLog."Record Time" := TIME();
            EVKOmnivaLog."Record Date and Time" := CREATEDATETIME(EVKOmnivaLog."Record Date", EVKOmnivaLog."Record Time");
            EVKOmnivaLog.INSERT();

        end;
    end;


    procedure OmnivaAuthorization()
    begin
        OmnivaApiClient.GetConnectionSettings(ServiceUrl, AuthorizationToken);
    end;



    [IntegrationEvent(false, false)]
    local procedure EventReassonCode(var ReasonCode: Code[10]; var UseReasonCode: Boolean; var PurchaseLine: Record "Purchase Line")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure InsertAdditionalInfo(var EVKOmnivaHeader: Record "EVK Omniva Header" TEMPORARY; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure InsertPurchaseLineNo(VAR EVKOmnivaLines: Record "EVK Omniva Lines" TEMPORARY; var PurchaseLine: Record "Purchase Line"; var UseSpecificGLAccount: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure InsertPurchaseLineAdditionalInfo(VAR EVKOmnivaHeader: Record "EVK Omniva Header" TEMPORARY; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure CheckIfVendorContractExist(VAR EVKOmnivaHeader: Record "EVK Omniva Header" TEMPORARY; var EVKOmnivaDimensions: Record "EVK Omniva Dimensions" TEMPORARY)
    begin
    end;




    procedure ExportVendors(VendorFilter: Text; AutomaticProcess: Boolean)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        VendorRecordRef: RecordRef;
        NumberFieldRef: FieldRef;
        RegistrationNoFieldRef: FieldRef;
        VendorNoList: List of [Code[20]];
        VendorNo: Code[20];
        RegistrationFieldNo: Integer;
        TotalVendors: Integer;
        ProcessedVendors: Integer;
        RegistrationNo: text[20];
        BankAccountNo: text[35];
        ClientRegistryRequestNode: XmlNode;
        VendorsElement: XmlElement;
        RegistrationNoElement: XmlElement;
        AccountNoElement: XmlElement;
        Name: XmlElement;
        BankAccountsElement: XmlElement;
        BankAccountElement: XmlElement;
        BankAccountNameElement: XmlElement;
        BankAccountNoElement: XmlElement;
        ContactsElement: XmlElement;
        ContactNameElement: XmlElement;
        VendorElement: XmlElement;

    begin
        clear(VendorNoList);
        Setup(ServiceUrl, AuthorizationToken);

        Clear(XmlRequestText);
        CreateXMLText(AuthorizationToken, XmlRequestText, 'ClientRegistryRequest');
        CreateDocXmlDocument(XmlRequestText, DocXmlDocument, Envelope, BodyList, DocumentNodes, EnvelopeNode, BodyNode);

        BodyList.Get(1, ClientRegistryRequestNode);

        VendorsElement := XmlElement.Create('Hankijad');
        ClientRegistryRequestNode.AsXmlElement().Add(VendorsElement);

        Clear(Vendor);
        Vendor.Reset();
        if AutomaticProcess then
            Vendor.SetRange("Omniva Automat", true)
        else begin
            Clear(ProgressDialog);
            ProgressDialog.OPEN(CalculatingLbl);
            Vendor.SetFilter("No.", VendorFilter);
            Vendor.SetRange(Omniva, true);
        end;
        TotalVendors := Vendor.COUNT;
        ProcessedVendors := 0;

        if Vendor.findset() then
            repeat
                RegistrationNo := '';
                VendorRecordRef.GetTABLE(Vendor);
                RegistrationFieldNo := EVKOmnivaSetup."Vendor Registration No. Field";
                if RegistrationFieldNo > 0 then begin
                    NumberFieldRef := VendorRecordRef.FIELD(1);
                    NumberFieldRef.SetRange(Vendor."No.");
                    VendorRecordRef.findfirst();
                    RegistrationNoFieldRef := VendorRecordRef.FIELD(RegistrationFieldNo);
                    RegistrationNo := RegistrationNoFieldRef.VALUE;
                end;

                if RegistrationNo <> '' then begin
                    if AutomaticProcess then
                        VendorNoList.Add(Vendor."No.")
                    else begin
                        ProgressDialog.UPDATE(1, ROUND(10000 * ProcessedVendors / TotalVendors, 1));
                        ProcessedVendors += 1;
                    end;
                    VendorElement := XmlElement.Create('Hankija');
                    VendorsElement.Add(VendorElement);

                    RegistrationNoElement := XmlElement.Create('CoRegNum');
                    TextNode := XmlText.Create(RegistrationNo);
                    RegistrationNoElement.Add(TextNode);
                    VendorElement.Add(RegistrationNoElement);

                    AccountNoElement := XmlElement.Create('AccountNum');
                    TextNode := XmlText.Create(Vendor."No.");

                    AccountNoElement.Add(TextNode);
                    VendorElement.Add(AccountNoElement);

                    Name := XmlElement.Create('Name');
                    TextNode := XmlText.Create(Vendor.Name + Vendor."Name 2");
                    Name.Add(TextNode);
                    VendorElement.Add(Name);

                    Clear(VendorBankAccount);
                    VendorBankAccount.Reset();
                    VendorBankAccount.SetRange("Vendor No.", Vendor."No.");
                    if not VendorBankAccount.IsEmpty then begin
                        BankAccountsElement := XmlElement.Create('Pangakontod');
                        VendorElement.Add(BankAccountsElement);
                        if VendorBankAccount.FINDset() then
                            repeat
                                BankAccountNo := VendorBankAccount."Bank Account No.";
                                if BankAccountNo = '' then
                                    BankAccountNo := COPYSTR(VendorBankAccount.IBAN, 1, MaxStrLen(BankAccountNo));
                                if BankAccountNo <> '' then begin
                                    BankAccountElement := XmlElement.Create('Pangakonto');
                                    BankAccountsElement.Add(BankAccountElement);

                                    BankAccountNameElement := XmlElement.Create('Name');
                                    TextNode := XmlText.Create(VendorBankAccount.Name + VendorBankAccount."Name 2");
                                    BankAccountNameElement.Add(TextNode);
                                    BankAccountElement.Add(BankAccountNameElement);

                                    BankAccountNoElement := XmlElement.Create('AccountNum');
                                    TextNode := XmlText.Create(BankAccountNo);
                                    BankAccountNoElement.Add(TextNode);
                                    BankAccountElement.Add(BankAccountNoElement);
                                end;
                            until VendorBankAccount.Next() = 0;
                    end;

                    if EVKOmnivaSetup."Vendor E-mail" then
                        if Vendor."E-Mail" <> '' then begin
                            ContactsElement := XmlElement.Create('Kontaktid');
                            VendorElement.Add(ContactsElement);

                            ContactNameElement := XmlElement.Create('Name');
                            TextNode := XmlText.Create(Vendor."E-Mail");
                            ContactNameElement.Add(TextNode);
                            ContactsElement.Add(ContactNameElement);
                        end;

                end;
            until Vendor.Next() = 0;

        HttpClientSend(XmlRequestText, DocXmlDocument, ServiceUrl, AutomaticProcess);
        if AutomaticProcess then
            Foreach VendorNo in VendorNoList do begin
                Clear(Vendor);
                Vendor.Reset();
                Vendor.SetRange("No.", VendorNo);
                Vendor.ModifyAll("Omniva Automat", false);
                Vendor.ModifyAll(Omniva, true);
            end
        else
            ProgressDialog.Close();
    end;

    procedure Setup(var ServiceUrlValue: text; var AuthorizationTokenValue: text)
    begin
        OmnivaApiClient.GetConnectionSettings(ServiceUrlValue, AuthorizationTokenValue);
    end;

    procedure CreateXMLText(AuthorizationTokenValue: text; var RequestText: text; ElementName: text)
    begin
        OmnivaApiClient.CreateRequestText(AuthorizationTokenValue, RequestText, ElementName);
    end;

    procedure CreateDocXmlDocument(RequestText: text; var XmlDocumentValue: XmlDocument; var EnvelopeElements: XmlNodeList;
        var BodyElements: XmlNodeList; var DocumentNodeList: XmlNodeList; var SoapEnvelopeNode: XmlNode; var SoapBodyNode: XmlNode)
    begin
        OmnivaApiClient.CreateDocument(RequestText, XmlDocumentValue, EnvelopeElements, BodyElements, DocumentNodeList, SoapEnvelopeNode, SoapBodyNode);
    end;

    procedure HttpClientSend(var RequestText: text; var XmlDocumentValue: XmlDocument; ServiceUrlValue: text; AutomaticProcess: Boolean)
    begin
        OmnivaApiClient.SendDocument(RequestText, XmlDocumentValue, ServiceUrlValue, AutomaticProcess);
    end;


    var
        EVKOmnivaSetup: Record "EVK Omniva Setup";
        EVKOmnivaLog: Record "EVK Omniva Log";
        GLAccount: Record "G/L Account";
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        OmnivaApiClient: Codeunit "EVK Omniva API Client";
        XmlRequestText: Text;
        AuthorizationToken: text;
        ServiceUrl: text;
        WrongDocumentTypeErr: label 'Wrong Document type';
        InvalidParametersErr: Label 'Invalid parameters';
        InvalidXmlFileErr: Label 'The selected file is not valid XML.', Comment = 'lt-LT="Pasirinktas failas nėra tinkamas XML dokumentas."';
        InvalidXmlResponseErr: Label 'Omniva returned an invalid XML response.', Comment = 'lt-LT="„Omniva“ grąžino netinkamą XML atsakymą."';
        InvalidXmlDateErr: Label 'The XML value "%1" is not a valid date.', Comment = 'lt-LT="XML reikšmė „%1“ nėra tinkama data."';
        InvalidXmlDecimalErr: Label 'The XML value "%1" is not a valid decimal number.', Comment = 'lt-LT="XML reikšmė „%1“ nėra tinkamas dešimtainis skaičius."';
        CalculatingLbl: label 'Calculating @1@@@@@@@@@@@@@@@@@@@';
        DocXmlDocument: XmlDocument;
        Envelope: XmlNodeList;
        BodyList: XmlNodeList;
        DocumentNodes: XmlNodeList;
        EnvelopeNode: XmlNode;
        BodyNode: XmlNode;
        TextNode: XmlText;
        ProgressDialog: Dialog;

}
