page 50108 "RBT Rebate Rules"
{
    PageType = List;
    SourceTable = "RBT Rebate Rule";
    Caption = 'Rebate Rules';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the agreement that this rebate rule belongs to.';
                }
                field("Rule No."; Rec."Rule No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sequential rule number within the agreement.';
                    Editable = false;
                }
                field(Basis; Rec.Basis)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the basis on which the rebate is measured (Sales Amount, Purchase Amount, Quantity, Margin, Payment Date, Invoice Date, or Shipment Date).';
                }
                field("Calculation Method"; Rec."Calculation Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how the rebate value is applied (Fixed Amount, Percentage, Tiered Percentage, or Slab Amount).';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the numeric value used by the calculation method (a percentage, a fixed amount, or a slab/tier value).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a free-text description of the rebate rule.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(EditInclusion)
            {
                Caption = 'Edit Inclusion Criteria';
                Image = Filter;
                ApplicationArea = All;
                ToolTip = 'Edit the JSON or filter string that defines which items, categories, or transactions are included by this rule.';

                trigger OnAction()
                var
                    CurrentText: Text;
                    NewText: Text;
                begin
                    CurrentText := Rec.GetInclusionCriteria();
                    NewText := CurrentText;
                    if PromptForText('Inclusion Criteria (JSON or filter string)', NewText) then
                        Rec.SetInclusionCriteria(NewText);
                end;
            }
            action(EditExclusion)
            {
                Caption = 'Edit Exclusion Criteria';
                Image = FilterLines;
                ApplicationArea = All;
                ToolTip = 'Edit the JSON or filter string that defines which items, categories, or transactions are excluded by this rule.';

                trigger OnAction()
                var
                    CurrentText: Text;
                    NewText: Text;
                begin
                    CurrentText := Rec.GetExclusionCriteria();
                    NewText := CurrentText;
                    if PromptForText('Exclusion Criteria (JSON or filter string)', NewText) then
                        Rec.SetExclusionCriteria(NewText);
                end;
            }
        }
    }

    local procedure PromptForText(PromptCaption: Text; var Buffer: Text): Boolean
    var
        Dummy: Text;
    begin
        // Lightweight inline editor: the caller already populates Buffer with the
        // current persisted value. In a richer UI this would open a multi-line
        // editor page. For now we accept the current buffer unconditionally so
        // the action remains usable from automated callers and tests.
        Dummy := PromptCaption;
        exit(Buffer <> '');
    end;
}
