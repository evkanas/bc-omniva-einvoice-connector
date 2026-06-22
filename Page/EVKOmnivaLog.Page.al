page 70102 "EVK Omniva Log"
{
    PageType = List;
    SourceTable = "EVK Omniva Log";
    UsageCategory = Lists;
    Caption = 'Omniva Logs', Comment = 'lt-LT="Omniva žurnalai"';
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                Caption = 'General', Comment = 'lt-LT="Bendra"';
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.', Comment = 'lt-LT="Nurodo įrašo numerį, priskirtą iš nurodytos numeracijos serijos, kai įrašas buvo sukurtas."';
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies vendor invoice no..', Comment = 'lt-LT="Nurodo tiekėjo sąskaitos numerį."';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies error information.', Comment = 'lt-LT="Nurodo klaidos informaciją."';
                }
                field("Record Date and Time"; Rec."Record Date and Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when Record is created.', Comment = 'lt-LT="Nurodo, kada sukurtas įrašas."';
                }
                field("Record Date"; Rec."Record Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when Record is created.', Comment = 'lt-LT="Nurodo, kada sukurtas įrašas."';
                }
                field("Record Time"; Rec."Record Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when Record is created.', Comment = 'lt-LT="Nurodo, kada sukurtas įrašas."';
                }
            }
        }
    }

}