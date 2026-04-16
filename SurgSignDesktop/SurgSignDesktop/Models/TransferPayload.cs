using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace SurgSignDesktop.Models;

/// <summary>
/// QR transfer format v2 — matches the Swift <c>TransferPayload</c> exactly.
///
/// <para>
/// Keys are single-letter and alphabetically ordered via <see cref="JsonPropertyOrderAttribute"/>
/// to reproduce the output of Swift's <c>JSONEncoder</c> with <c>.sortedKeys</c>.
/// </para>
/// </summary>
public sealed class TransferPayload
{
    /// <summary>Shift label — <c>"AM"</c> or <c>"PM"</c>.</summary>
    [JsonPropertyName("from")]
    [JsonPropertyOrder(0)]
    public string From { get; set; } = "AM";

    /// <summary>Patient DTOs.</summary>
    [JsonPropertyName("pts")]
    [JsonPropertyOrder(1)]
    public List<PatientDTO> Pts { get; set; } = new();

    /// <summary>Service name.</summary>
    [JsonPropertyName("svc")]
    [JsonPropertyOrder(2)]
    public string Svc { get; set; } = string.Empty;

    /// <summary>Schema version — always <c>2</c>.</summary>
    [JsonPropertyName("v")]
    [JsonPropertyOrder(3)]
    public int V { get; set; } = 2;
}

/// <summary>
/// Patient DTO — single-letter keys (alphabetically ordered).
/// </summary>
public sealed class PatientDTO
{
    [JsonPropertyName("al")]
    [JsonPropertyOrder(0)]
    public string Al { get; set; } = string.Empty;

    [JsonPropertyName("cs")]
    [JsonPropertyOrder(1)]
    public string Cs { get; set; } = string.Empty;

    [JsonPropertyName("dx")]
    [JsonPropertyOrder(2)]
    public string Dx { get; set; } = string.Empty;

    [JsonPropertyName("id")]
    [JsonPropertyOrder(3)]
    public string Id { get; set; } = string.Empty;

    /// <summary>Tasks array — Swift uses <c>"is"</c> as the CodingKey.</summary>
    [JsonPropertyName("is")]
    [JsonPropertyOrder(4)]
    public List<TaskDTO> Is { get; set; } = new();

    [JsonPropertyName("m")]
    [JsonPropertyOrder(5)]
    public string M { get; set; } = string.Empty;

    [JsonPropertyName("n")]
    [JsonPropertyOrder(6)]
    public string N { get; set; } = string.Empty;

    [JsonPropertyName("nt")]
    [JsonPropertyOrder(7)]
    public string Nt { get; set; } = string.Empty;

    [JsonPropertyName("pr")]
    [JsonPropertyOrder(8)]
    public string Pr { get; set; } = string.Empty;

    [JsonPropertyName("px")]
    [JsonPropertyOrder(9)]
    public string Px { get; set; } = string.Empty;

    [JsonPropertyName("r")]
    [JsonPropertyOrder(10)]
    public string R { get; set; } = string.Empty;

    [JsonPropertyName("s")]
    [JsonPropertyOrder(11)]
    public string S { get; set; } = string.Empty;

    [JsonPropertyName("sd")]
    [JsonPropertyOrder(12)]
    public string Sd { get; set; } = string.Empty;
}

/// <summary>
/// Task DTO — single-letter keys, alphabetically ordered (<c>d</c>, <c>id</c>, <c>t</c>).
/// </summary>
public sealed class TaskDTO
{
    /// <summary>Done flag — 1 if done, 0 if not.</summary>
    [JsonPropertyName("d")]
    [JsonPropertyOrder(0)]
    public int D { get; set; }

    [JsonPropertyName("id")]
    [JsonPropertyOrder(1)]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("t")]
    [JsonPropertyOrder(2)]
    public string T { get; set; } = string.Empty;
}
