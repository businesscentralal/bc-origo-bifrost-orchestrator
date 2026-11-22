namespace Origo.Bifrost.Orchestrator;

using System.IO;

/// <summary>Adds Swap Amount Sign to BC's Transformation Rule types (port of Tools for Power Users).</summary>
enumextension 10035606 "Swap Amount Sign ori" extends "Transformation Rule Type"
{
    value(10035606; "Swap Amount Sign ori")
    {
        Caption = 'Swap Amount Sign', Comment = 'is-IS=Breyta formerki upphæðar';
        Implementation = "Transformation Rule" = "Swap Amount Sign ori";
    }
}
