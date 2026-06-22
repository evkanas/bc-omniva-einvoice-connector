tableextension 70106 "EVK Omniva Vendor" extends Vendor
{
    fields
    {
        field(70100; Omniva; Boolean)
        {
            Caption = 'Omniva', Comment = 'lt-LT="Omniva"';
            DataClassification = CustomerContent;
            AllowInCustomizations = Never;
        }
        field(70101; "Omniva Automat"; Boolean)
        {
            Caption = 'Omniva Automat', Comment = 'lt-LT="Omniva automat"';
            DataClassification = CustomerContent;
            AllowInCustomizations = Never;
        }
    }

}