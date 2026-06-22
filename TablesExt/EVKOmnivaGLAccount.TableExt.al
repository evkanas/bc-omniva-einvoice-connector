tableextension 70101 "EVK Omniva G/L Account" extends "G/L Account"
{
    fields
    {
        field(70100; Omniva; Boolean)
        {
            Caption = 'Omniva', Comment = 'lt-LT="Omniva"';
            DataClassification = CustomerContent;
        }
    }

}