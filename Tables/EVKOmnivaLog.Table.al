table 70104 "EVK Omniva Log"
{
    Caption = 'Omniva Logs', Comment = 'lt-LT="Omniva žurnalai"';
    fields
    {
        field(10; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Comment = 'lt-LT="Įrašo Nr."';
            DataClassification = CustomerContent;
        }
        field(20; "Vendor Invoice No."; code[35])
        {
            Caption = 'Vendor Invoice No.', Comment = 'lt-LT="Tiekėjo Sąskaitos Nr."';
            DataClassification = CustomerContent;
        }
        field(30; Comment; text[300])
        {
            Caption = 'Comment', Comment = 'lt-LT="Komentaras"';
            DataClassification = CustomerContent;
        }
        field(40; "Record Date"; date)
        {
            Caption = 'Record Date', Comment = 'lt-LT="Įrašo Data"';
            DataClassification = CustomerContent;
        }
        field(50; "Record Time"; Time)
        {
            Caption = 'Record Time', Comment = 'lt-LT="Įrašo Laikas"';
            DataClassification = CustomerContent;
        }
        field(60; "Record Date and Time"; datetime)
        {
            Caption = 'Record Date and Time', Comment = 'lt-LT="Įrašo Data ir Laikas"';
            DataClassification = CustomerContent;
        }

    }
    keys
    {
        key(PrimaryKey; "Entry No.")
        {
            Clustered = true;
        }
    }
}