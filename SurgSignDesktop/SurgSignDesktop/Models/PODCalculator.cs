using System;

namespace SurgSignDesktop.Models;

/// <summary>
/// Utility for calculating post-operative day (POD) values.
/// Mirrors the Swift <c>PODCalculator</c>.
/// </summary>
public static class PODCalculator
{
    /// <summary>
    /// Returns the number of days since surgery, or <c>null</c> if no surgery date.
    /// Negative values indicate pre-op.
    /// </summary>
    public static int? Calculate(DateTime? surgeryDate)
    {
        if (surgeryDate is null) return null;
        var startOfSurgery = surgeryDate.Value.Date;
        var startOfToday = DateTime.Now.Date;
        return (int)(startOfToday - startOfSurgery).TotalDays;
    }

    /// <summary>
    /// Returns a label like <c>"Pre-Op"</c>, <c>"POD 0"</c>, <c>"POD 3"</c>, or <c>null</c> if no surgery date.
    /// </summary>
    public static string? Label(DateTime? surgeryDate)
    {
        var pod = Calculate(surgeryDate);
        if (pod is null) return null;
        return pod < 0 ? "Pre-Op" : $"POD {pod}";
    }
}
