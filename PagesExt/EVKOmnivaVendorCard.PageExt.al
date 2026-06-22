pageextension 70108 "EVK Omniva Vendor Card" extends "Vendor Card"
{
    layout
    {
        addafter("Disable Search by Name")
        {
            field(Omniva; Rec.Omniva)
            {
                ApplicationArea = all;
                ToolTip = 'Specifies g/l account for e-invoice.';
                Visible = visible_omniva;
            }
            field("Omniva Automat"; Rec."Omniva Automat")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the automatic import of the vendor into Omniva system.';
                trigger OnValidate()
                begin
                    if Rec."Omniva Automat" then
                        Rec.Omniva := false;
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        EVKOmnivaSetup.Get();
        visible_omniva := false;
        if EVKOmnivaSetup.Environment <> EVKOmnivaSetup.Environment::" " then
            visible_omniva := true;
    end;

    var
        EVKOmnivaSetup: Record "EVK Omniva Setup";
        visible_omniva: boolean;
}