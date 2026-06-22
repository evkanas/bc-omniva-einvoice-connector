table 70100 "EVK Omniva Dimensions"
{
    Caption = 'Omniva Dimensions', Comment = 'lt-LT="Omniva dimensijos"';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(10; "Header ID"; Integer)
        {
            AllowInCustomizations = Never;
        }
        field(20; "Line ID"; Integer)
        {
            AllowInCustomizations = Never;
        }
        field(30; "ID"; Integer)
        {
            AllowInCustomizations = Never;
        }
        field(40; "Dimension Code"; Code[20])
        {
            AllowInCustomizations = Never;
        }
        field(50; "Dimension Name"; Code[20])
        {
            AllowInCustomizations = Never;
        }
    }
    keys
    {
        key(PrimaryKey; "Header ID", "Line ID", "ID")
        {
            Clustered = true;
        }
    }
}