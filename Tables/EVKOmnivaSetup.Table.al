table 70103 "EVK Omniva Setup"
{
    Caption = 'Omniva Setup', Comment = 'lt-LT="Omniva nustatymai"';
    DataClassification = CustomerContent;

    fields
    {
        field(10; "Primary Key"; code[10])
        {
            Caption = 'Primary Key', Comment = 'lt-LT="Pirminis raktas"';
            AllowInCustomizations = Never;
        }
        field(20; "Environment"; Option)
        {
            Caption = 'Environment', Comment = 'lt-LT="Aplinka"';
            OptionMembers = " ","Prod","Dev";
            OptionCaption = ' ,Prod,Dev', Comment = 'lt-LT=" ,Prod,Dev"';
            AllowInCustomizations = Never;

        }
        field(30; "API URL"; text[100])
        {
            Caption = 'API URL', Comment = 'lt-LT="API URL"';
            AllowInCustomizations = Never;
        }
        field(40; "API URL Dev"; text[100])
        {
            Caption = 'API URL Dev', Comment = 'lt-LT="API URL Dev"';
            AllowInCustomizations = Never;
        }
        field(50; Authorization; text[100])
        {
            Caption = 'Authorization', Comment = 'lt-LT="Autorizacija"';
            AllowInCustomizations = Never;
        }
        field(60; "Authorization Dev"; text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Authorization Dev', Comment = 'lt-LT="Autorizacija Dev"';
            AllowInCustomizations = Never;
        }
        field(70; "Vendor Registration No. Field"; Integer)
        {
            Caption = 'Vendor Registration No. Field', Comment = 'lt-LT="Pardavėjo registracijos Nr. laukas"';
            AllowInCustomizations = Never;
        }
        field(80; "Vendor E-mail"; Boolean)
        {
            Caption = 'Vendor E-mail', Comment = 'lt-LT="Pardavėjo el. paštas"';
            AllowInCustomizations = Never;
        }
        field(90; "Last Import Time"; text[30])
        {
            Caption = 'Last Import Time', Comment = 'lt-LT="Paskutinio importo laikas"';
            AllowInCustomizations = Never;
        }
        field(100; "No. Series"; code[10])
        {
            Caption = 'No. Series', Comment = 'lt-LT="Nr. serija"';
            TableRelation = "No. Series";
            AllowInCustomizations = Never;
        }
        field(110; "Omniva Autopost"; Boolean)
        {
            Caption = 'Omniva Autopost', Comment = 'lt-LT="Omniva automatinis paskelbimas"';
            AllowInCustomizations = Never;
        }
        field(120; "Download File"; Boolean)
        {
            Caption = 'Download File', Comment = 'lt-LT="Atsisiųsti failą"';
            AllowInCustomizations = Never;
        }

    }
    keys
    {
        key(PrimaryKey; "Primary Key")
        {
            Clustered = true;
        }
    }
}
