using System;

namespace SurgSignDesktop.Models;

/// <summary>
/// Clinical priority level for a patient, ordered from most to least urgent.
/// Raw string values match the Swift <c>Priority</c> enum so the QR wire format stays identical.
/// </summary>
public enum Priority
{
    High,
    Medium,
    Low,
    Stable
}

public static class PriorityExtensions
{
    /// <summary>
    /// Returns the raw Swift-compatible string for this priority.
    /// </summary>
    public static string RawValue(this Priority priority) => priority switch
    {
        Priority.High => "high",
        Priority.Medium => "medium",
        Priority.Low => "low",
        Priority.Stable => "stable",
        _ => "stable"
    };

    /// <summary>
    /// Capitalized display label.
    /// </summary>
    public static string Label(this Priority priority) => priority switch
    {
        Priority.High => "High",
        Priority.Medium => "Medium",
        Priority.Low => "Low",
        Priority.Stable => "Stable",
        _ => "Stable"
    };

    /// <summary>
    /// Sort order — lower is higher priority.
    /// </summary>
    public static int SortOrder(this Priority priority) => priority switch
    {
        Priority.High => 0,
        Priority.Medium => 1,
        Priority.Low => 2,
        Priority.Stable => 3,
        _ => 3
    };

    /// <summary>
    /// Parse a Swift raw value back into a <see cref="Priority"/> enum.
    /// Unknown values fall back to <see cref="Priority.Stable"/>.
    /// </summary>
    public static Priority FromRawValue(string? raw) => raw switch
    {
        "high" => Priority.High,
        "medium" => Priority.Medium,
        "low" => Priority.Low,
        "stable" => Priority.Stable,
        _ => Priority.Stable
    };
}
