pageextension 70107 "EVK Omniva Purchase Invoice" extends "Purchase Invoice"
{
    layout
    {
        addafter("Assigned User ID")
        {
            field("Omniva Date"; Rec."Omniva Date")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies invoice imported date.';
                Visible = visible_omniva;
            }
            field("Omniva Autopost"; Rec."Omniva Autopost")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies automated invoice posting.';
                Visible = visible_omniva;
                Editable = false;
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