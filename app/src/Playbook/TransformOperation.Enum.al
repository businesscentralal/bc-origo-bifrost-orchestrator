namespace Origo.Bifrost.Orchestrator;

/// <summary>Operations supported by a local JSON field mapping.</summary>
enum 10035624 "Transform Operation ori"
{
    /// <summary>Preserves the source JSON token and its type.</summary>
    value(0; Copy) { Caption = 'Copy', Comment = 'is-IS=Afrita'; }
    /// <summary>Uses Argument 1 as a literal text value.</summary>
    value(1; Constant) { Caption = 'Constant', Comment = 'is-IS=Fasti'; }
    /// <summary>Changes the sign of an invariant numeric value.</summary>
    value(2; Negate) { Caption = 'Negate', Comment = 'is-IS=Skipta um formerki'; }
    /// <summary>Replaces literal text, preserving case sensitivity.</summary>
    value(3; "Replace Text") { Caption = 'Replace Text', Comment = 'is-IS=Skipta út texta'; }
}
