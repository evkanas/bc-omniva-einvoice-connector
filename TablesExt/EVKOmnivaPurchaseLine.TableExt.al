tableextension 70105 "EVK Omniva Purchase Line" extends "Purchase Line"
{
    fields
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                RestorelLine();
            end;
        }
        modify(Type)
        {
            trigger OnAfterValidate()
            begin
                RestorelLine();
            end;
        }
        modify("Location Code")
        {
            trigger OnAfterValidate()
            begin
                RestorelLine();
            end;
        }
    }

    procedure RestorelLine()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        clear(PurchaseHeader);
        PurchaseHeader.reset();
        PurchaseHeader.SetRange("Document Type", "Document Type");
        PurchaseHeader.SetRange("No.", "Document No.");
        if PurchaseHeader.findfirst() then
            if PurchaseHeader."Omniva Date" <> 0D then begin
                if xRec.Description <> '' then
                    Description := xRec.Description;
                Quantity := xRec.Quantity;
                "Unit of Measure" := xRec."Unit of Measure";
                "Unit of Measure Code" := xRec."Unit of Measure Code";
                Quantity := xRec.Quantity;
                "Line Amount" := xRec."Line Amount";
                "Direct Unit Cost" := xRec."Direct Unit Cost";
                "Shortcut Dimension 1 Code" := xRec."Shortcut Dimension 1 Code";
                "Shortcut Dimension 2 Code" := xRec."Shortcut Dimension 2 Code";
                "Dimension Set ID" := xRec."Dimension Set ID";

                RestorelLineMoreParameter(Rec, xRec);
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure RestorelLineMoreParameter(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;
}