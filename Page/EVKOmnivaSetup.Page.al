page 70100 "EVK Omniva Setup"
{
    PageType = Card;
    SourceTable = "EVK Omniva Setup";
    ApplicationArea = Basic, Suite;
    DeleteAllowed = false;
    InsertAllowed = false;
    UsageCategory = Administration;
    Caption = 'Omniva Setup', Comment = 'lt-LT="Omniva nustatymai"';
    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'lt-LT="Bendra"';

                field(Environment; Rec.Environment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Environment.', Comment = 'lt-LT="Nurodo aplinką."';
                }
                field("API URL"; Rec."API URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies api url.', Comment = 'lt-LT="Nurodo api url."';
                }
                field(Authorization; Rec.Authorization)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies api authorization.', Comment = 'lt-LT="Nurodo api autorizaciją."';
                }
                field("API URL Dev"; Rec."API URL Dev")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies api url for dev environment.', Comment = 'lt-LT="Nurodo api url dev aplinkai."';
                }
                field("Authorization Dev"; Rec."Authorization Dev")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies api authorization for dev environment.', Comment = 'lt-LT="Nurodo api autorizaciją dev aplinkai."';
                }
                field("Vendor E-mail"; Rec."Vendor E-mail")
                {
                    ApplicationArea = All;
                    ToolTip = 'Send Vendor E-mail address to e-invoice system.', Comment = 'lt-LT="Siųsti tiekėjo el. pašto adresą į e-faktūros sistemą."';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies no. series.', Comment = 'lt-LT="Nurodo numerų seriją."';
                }
                field("Omniva Autopost"; Rec."Omniva Autopost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Automatically post invoice.', Comment = 'lt-LT="Automatiškai paskelbti sąskaitą faktūrą."';
                }
                field("Vendor Registration No. Field"; Rec."Vendor Registration No. Field")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies vendor registration no. field.', Comment = 'lt-LT="Nurodo tiekėjo registracijos numerio lauką."';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Field: Record Field;
                        PFields: Page "Fields Lookup";
                    begin
                        Clear(Field);
                        Field.Reset();
                        Field.SetRange(TableNo, 23);
                        Clear(PFields);
                        PFields.SETTABLEVIEW(Field);
                        PFields.LOOKUPMODE(true);
                        if PFields.RUNMODAL() = Action::LookupOK then begin
                            PFields.GetRECORD(Field);
                            Rec."Vendor Registration No. Field" := Field."No.";
                        end;
                    end;
                }
                field("Last Import Time"; Rec."Last Import Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies last import time from e-invoice system.', Comment = 'lt-LT="Nurodo paskutinį importo laiką iš e-faktūros sistemos."';
                }
                field("Download File"; Rec."Download File")
                {
                    ApplicationArea = All;
                    ToolTip = 'Download e-invoice file.', Comment = 'lt-LT="Atsisiųsti e-faktūros failą."';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if NOT Rec.Get() then begin
            Rec.INIT();
            Rec.Environment := Rec.Environment::Dev;
            Rec."API URL" := 'https://finance.omniva.eu/finance/erp/';
            Rec.Authorization := 'REPLACE_WITH_PRODUCTION_AUTHORIZATION_VALUE';
            Rec."API URL Dev" := 'https://testfinance.post.ee/finance/erp/erpServices.wsdl';
            Rec."Authorization Dev" := 'REPLACE_WITH_TEST_AUTHORIZATION_VALUE';
            Rec."Omniva Autopost" := true;
            Rec."Vendor E-mail" := true;
            Rec."Download File" := true;

            // Example: set this to the field number that stores the vendor registration code.
            Rec."Vendor Registration No. Field" := 0;
            Rec.INSERT();
        end;

    end;
}