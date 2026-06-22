table 70101 "EVK Omniva Header"
{
    Caption = 'Omniva Header', Comment = 'lt-LT="Omniva antraštė"';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(10; ID; Integer)
        {
            AllowInCustomizations = Never;
        }
        field(20; "Vendor No."; Code[20])
        {
            AllowInCustomizations = Never;
        }
        field(30; "Posting Date"; Date)
        {
            AllowInCustomizations = Never;
        }
        field(40; "Due Date"; Date)
        {
            AllowInCustomizations = Never;
        }
        field(50; "Vendor Invoice No."; Code[20])
        {
            AllowInCustomizations = Never;
        }
        field(60; "Currency Code"; Code[3])
        {
            AllowInCustomizations = Never;
        }
        field(70; "Bank Account No."; Code[30])
        {
            AllowInCustomizations = Never;
        }
        field(80; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            AllowInCustomizations = Never;
        }
        field(90; "Applies-to Doc. No."; Code[20])
        {
            AllowInCustomizations = Never;
        }
        field(100; "Vendor Company Code"; Code[20])
        {
            AllowInCustomizations = Never;
        }
        field(110; "Invoice Type"; Code[3])
        {
            AllowInCustomizations = Never;
        }
        field(120; "Applies-to Invoice No."; Code[20])
        {
            AllowInCustomizations = Never;
        }
        field(130; "Assigned No."; Code[20])
        {
            AllowInCustomizations = Never;
        }
        field(140; "Errors"; Boolean)
        {
            AllowInCustomizations = Never;
        }
        field(150; "Bank Code"; Code[10])
        {
            AllowInCustomizations = Never;
        }
        field(160; "Omniva SF ID"; Code[20])
        {
            AllowInCustomizations = Never;
        }
        field(170; "Purchase SF No."; Code[20])
        {
            AllowInCustomizations = Never;
        }
        field(180; "SF Label"; Text[30])
        {
            AllowInCustomizations = Never;
        }
        field(190; "Vendor Navision No."; Code[20])
        {
            AllowInCustomizations = Never;
        }
        field(200; "Contract No."; Code[20])
        {
            AllowInCustomizations = Never;
        }
        field(210; "Total VAT Sum"; Decimal)
        {
            AllowInCustomizations = Never;
        }

    }
    keys
    {
        key(PrimaryKey; ID)
        {
            Clustered = true;
        }
    }
}