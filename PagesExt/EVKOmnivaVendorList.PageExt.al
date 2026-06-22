pageextension 70109 "EVK Omniva Vendor List" extends "Vendor List"
{
    layout
    {
        addafter(Name)
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
                ToolTip = 'Specifies the automatic import of the vendor into Omniva systemm .';
            }
        }
    }

    trigger OnOpenPage()
    begin
        visible_omniva := false;
        if EVKOmnivaSetup.Get() then begin
            visible_omniva := false;
            if EVKOmnivaSetup.Environment <> EVKOmnivaSetup.Environment::" " then
                visible_omniva := true;
        end;
    end;

    var
        EVKOmnivaSetup: Record "EVK Omniva Setup";
        visible_omniva: boolean;
}