table 50102 "RBT Rebate Rule"
{
    Caption = 'RBT Rebate Rule';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            DataClassification = CustomerContent;
            TableRelation = "RBT Rebate Agreement"."No.";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(10; Basis; Enum "RBT Rebate Basis")
        {
            Caption = 'Basis';
            DataClassification = CustomerContent;
        }
        field(11; "Calculation Method"; Enum "RBT Calculation Method")
        {
            Caption = 'Calculation Method';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                case "Calculation Method" of
                    "Calculation Method"::Fixed:
                        begin
                            Percentage := 0;
                        end;
                    "Calculation Method"::Percentage,
                    "Calculation Method"::Tiered,
                    "Calculation Method"::Slab,
                    "Calculation Method"::Growth:
                        begin
                            "Fixed Amount" := 0;
                        end;
                end;
            end;
        }
        field(12; Threshold; Decimal)
        {
            Caption = 'Threshold';
            DataClassification = CustomerContent;
            MinValue = 0;
            DecimalPlaces = 0 : 5;
        }
        field(13; Percentage; Decimal)
        {
            Caption = 'Percentage';
            DataClassification = CustomerContent;
            MinValue = 0;
            MaxValue = 100;
            DecimalPlaces = 0 : 5;
        }
        field(14; "Fixed Amount"; Decimal)
        {
            Caption = 'Fixed Amount';
            DataClassification = CustomerContent;
            MinValue = 0;
            AutoFormatType = 1;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
        }
        field(21; "Item Category"; Code[20])
        {
            Caption = 'Item Category';
            DataClassification = CustomerContent;
            TableRelation = "Item Category".Code;
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }
    }

    keys
    {
        key(PK; "Agreement No.", "Line No.")
        {
            Clustered = true;
        }
        key(ItemKey; "Agreement No.", "Item No.") { }
        key(CategoryKey; "Agreement No.", "Item Category") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Agreement No.", "Line No.", Basis, "Calculation Method", Percentage, "Fixed Amount") { }
        fieldgroup(Brick; "Agreement No.", "Line No.", Basis, "Calculation Method", Percentage, "Fixed Amount") { }
    }

    var
        MissingAgreementErr: Label 'Rebate Rule cannot be created because the referenced Rebate Agreement %1 does not exist. Create the agreement first on the RBT Rebate Agreement Card.';

    trigger OnInsert()
    var
        RebateAgreement: Record "RBT Rebate Agreement";
    begin
        if "Agreement No." = '' then
            exit;
        if not RebateAgreement.Get("Agreement No.") then
            Error(MissingAgreementErr, "Agreement No.");
        if "Line No." = 0 then
            "Line No." := GetNextLineNo();
    end;

    local procedure GetNextLineNo(): Integer
    var
        RebateRule: Record "RBT Rebate Rule";
    begin
        RebateRule.SetRange("Agreement No.", "Agreement No.");
        if RebateRule.FindLast() then
            exit(RebateRule."Line No." + 10000);
        exit(10000);
    end;
}
