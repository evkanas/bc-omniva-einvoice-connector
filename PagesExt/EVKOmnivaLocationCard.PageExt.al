pageextension 70105 "EVK Omniva Location Card" extends "Location Card"
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