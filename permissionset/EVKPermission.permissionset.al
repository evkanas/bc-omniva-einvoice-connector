
permissionset 70100 "EVK Permission"
{
    Assignable = true;
    Permissions = tabledata "EVK Omniva Header" = RIMD,
        tabledata "EVK Omniva Lines" = RIMD,
        tabledata "EVK Omniva Log" = RIMD,
        tabledata "EVK Omniva Setup" = RIMD,
        tabledata "EVK Omniva Dimensions" = RIMD,
        table "EVK Omniva Header" = X,
        table "EVK Omniva Lines" = X,
        table "EVK Omniva Log" = X,
        table "EVK Omniva Setup" = X,
        table "EVK Omniva Dimensions" = X,
        codeunit "EVK Omniva" = X,
        codeunit "EVK Omniva API Client" = X,
        page "EVK Omniva Export" = X,
        page "EVK Omniva Log" = X,
        page "EVK Omniva Setup" = X;
}
