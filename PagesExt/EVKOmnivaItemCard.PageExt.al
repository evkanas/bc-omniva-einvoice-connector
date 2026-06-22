pageextension 70103 "EVK Omniva Item Card" extends "Item Card"
{
    layout
    {
        addafter("Purchasing Code")
        {
            field(Omniva; Rec.Omniva)
            {
                ApplicationArea = all;
                ToolTip = 'Specifies item for e-invoice.';
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