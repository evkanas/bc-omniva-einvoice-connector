pageextension 70102 "EVK Omniva G/L Account List" extends "G/L Account List"
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