page 50113 "RBT Recalc Retroactive Dialog"
{
    // Lightweight modal dialog page used by the Rebate Agreement Card's
    // 'Recalc Retroactive...' action to capture Period Start, Period End,
    // and Posting Date before delegating to codeunit "RBT Recalc Engine".
    //
    // Contains NO business logic - it only captures user input. All delta
    // computation and posting happens in the codeunit, per the platform
    // 'management codeunit' rule.

    PageType = StandardDialog;
    Caption = 'Retroactive Recalculation';
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(Period)
            {
                Caption = 'Period';

                field(PeriodStartField; PeriodStart)
                {
                    ApplicationArea = All;
                    Caption = 'Period Start';
                    ToolTip = 'The first day of the historical period to re-evaluate against the current agreement version.';
                }
                field(PeriodEndField; PeriodEnd)
                {
                    ApplicationArea = All;
                    Caption = 'Period End';
                    ToolTip = 'The last day of the historical period to re-evaluate against the current agreement version.';
                }
                field(PostingDateField; PostingDate)
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date';
                    ToolTip = 'The posting date to stamp on the resulting delta Calc Request and its G/L journal.';
                }
            }
        }
    }

    var
        PeriodStart: Date;
        PeriodEnd: Date;
        PostingDate: Date;

    /// <summary>
    /// Pre-populates the three date fields before RunModal. Called by the Agreement
    /// Card action so the dialog opens with sensible defaults (typically the agreement's
    /// Start/End dates and WorkDate for posting).
    /// </summary>
    procedure SetDefaults(DefaultPeriodStart: Date; DefaultPeriodEnd: Date; DefaultPostingDate: Date)
    begin
        PeriodStart := DefaultPeriodStart;
        PeriodEnd := DefaultPeriodEnd;
        PostingDate := DefaultPostingDate;
    end;

    /// <summary>
    /// Returns the values captured on the dialog to the calling action. Callers must
    /// only trust these values after RunModal returned Action::OK.
    /// </summary>
    procedure GetValues(var OutPeriodStart: Date; var OutPeriodEnd: Date; var OutPostingDate: Date)
    begin
        OutPeriodStart := PeriodStart;
        OutPeriodEnd := PeriodEnd;
        OutPostingDate := PostingDate;
    end;
}
