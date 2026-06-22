table 70102 "EVK Omniva Lines"
{
    Caption = 'Omniva Lines', Comment = 'lt-LT="Omniva eilutės"';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(10; "Header ID"; Integer)
        {
            AllowInCustomizations = Never;
        }
        field(20; ID; Integer)
        {
            AllowInCustomizations = Never;
        }
        field(30; "G/L Account Code"; code[20]) { AllowInCustomizations = Never; }
        field(40; "Description 1"; text[50]) { AllowInCustomizations = Never; }
        field(50; "Description 2"; text[50]) { AllowInCustomizations = Never; }
        field(60; "VAT Code"; code[10]) { AllowInCustomizations = Never; }
        field(70; "Unit of Measure"; code[10]) { AllowInCustomizations = Never; }
        field(80; Quantity; Decimal) { }
        field(90; "Item Price"; Decimal) { AllowInCustomizations = Never; }
        field(100; "Item No."; code[20]) { AllowInCustomizations = Never; }
        field(110; "Line Amount"; Decimal) { AllowInCustomizations = Never; }
        field(120; "Contract No."; code[20]) { AllowInCustomizations = Never; }
    }
    keys
    {
        key(PrimaryKey; "Header ID", ID)
        {
            Clustered = true;
        }
    }
}