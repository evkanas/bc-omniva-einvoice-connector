tableextension 70104 "EVK Omniva Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(70100; "Omniva Date"; date)
        {
            Caption = 'Omniva Date', Comment = 'lt-LT="Omniva data"';
            DataClassification = CustomerContent;
        }
        field(70101; "Omniva Autopost"; Boolean)
        {
            Caption = 'Omniva Autopost', Comment = 'lt-LT="Omniva automatinis paskelbimas"';
            DataClassification = CustomerContent;
        }
    }

}