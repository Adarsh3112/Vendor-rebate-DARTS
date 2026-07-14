table 50111 "RBT Settlement Line"
{
    Caption = 'RBT Settlement Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Settlement No."; Code[20])
        {
            Caption = 'Settlement No.';
            DataClassification = CustomerContent;
            TableRelation = "RBT Settlement Header"."No.";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(10; "Calc Request No."; Code[20])
        {
            Caption = 'Calc Request No.';
            DataClassification = CustomerContent;
            TableRelation = "RBT Calc Request"."No.";
        }
        field(11; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            DataClassification = CustomerContent;
            TableRelation = "RBT Rebate Agreement"."No.";
        }
        field(12; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
        }
        field(13; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = CustomerContent;
            TableRelation = Customer;
        }
        field(14; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
        }
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;
        }
        field(16; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(17; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Settlement No.", "Line No.")
        {
            Clustered = true;
        }
        key(CalcRequestKey; "Calc Request No.") { }
    }

    var
        AllowInternalEdit: Boolean;
        ParentPostedImmutableErr: Label 'Settlement %1 has Status = Posted. Its lines cannot be modified or deleted.', Comment = '%1 = Settlement No.';

    trigger OnInsert()
    var
        LastLine: Record "RBT Settlement Line";
    begin
        if "Line No." = 0 then begin
            LastLine.SetRange("Settlement No.", "Settlement No.");
            if LastLine.FindLast() then
                "Line No." := LastLine."Line No." + 10000
            else
                "Line No." := 10000;
        end;
    end;

    trigger OnModify()
    begin
        if AllowInternalEdit then
            exit;
        CheckParentNotPosted();
    end;

    trigger OnDelete()
    begin
        if AllowInternalEdit then
            exit;
        CheckParentNotPosted();
    end;

    local procedure CheckParentNotPosted()
    var
        Header: Record "RBT Settlement Header";
    begin
        if not Header.Get("Settlement No.") then
            exit;
        if Header.Status = Header.Status::Posted then
            Error(ParentPostedImmutableErr, Header."No.");
    end;

    procedure SetAllowInternalEdit(NewValue: Boolean)
    begin
        AllowInternalEdit := NewValue;
    end;
}
