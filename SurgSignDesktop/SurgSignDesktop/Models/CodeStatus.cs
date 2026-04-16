using System;

namespace SurgSignDesktop.Models;

/// <summary>
/// Patient code status for resuscitation directives.
/// Raw string values match the Swift <c>CodeStatus</c> enum so the QR wire format stays identical.
/// </summary>
public enum CodeStatus
{
    FullCode,
    DNR,
    DNI,
    DNRDNI,
    ComfortMeasures
}

public static class CodeStatusExtensions
{
    /// <summary>
    /// Returns the raw Swift-compatible string for this code status.
    /// </summary>
    public static string RawValue(this CodeStatus status) => status switch
    {
        CodeStatus.FullCode => "Full Code",
        CodeStatus.DNR => "DNR",
        CodeStatus.DNI => "DNI",
        CodeStatus.DNRDNI => "DNR/DNI",
        CodeStatus.ComfortMeasures => "Comfort Measures",
        _ => "Full Code"
    };

    /// <summary>
    /// Abbreviated label for compact UI display.
    /// </summary>
    public static string ShortLabel(this CodeStatus status) => status switch
    {
        CodeStatus.FullCode => "Full",
        CodeStatus.DNR => "DNR",
        CodeStatus.DNI => "DNI",
        CodeStatus.DNRDNI => "DNR/DNI",
        CodeStatus.ComfortMeasures => "CMO",
        _ => "Full"
    };

    /// <summary>
    /// Parse a Swift raw value back into a <see cref="CodeStatus"/>.
    /// Unknown values fall back to <see cref="CodeStatus.FullCode"/>.
    /// </summary>
    public static CodeStatus FromRawValue(string? raw) => raw switch
    {
        "Full Code" => CodeStatus.FullCode,
        "DNR" => CodeStatus.DNR,
        "DNI" => CodeStatus.DNI,
        "DNR/DNI" => CodeStatus.DNRDNI,
        "Comfort Measures" => CodeStatus.ComfortMeasures,
        _ => CodeStatus.FullCode
    };
}
