using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;
using SurgSignDesktop.Models;

namespace SurgSignDesktop.Services;

/// <summary>
/// Loads and saves the patient list to <c>%APPDATA%\SurgSign\patients.json</c>.
/// Writes are atomic (temp file + <see cref="File.Move(string, string, bool)"/>).
/// </summary>
public class PersistenceService
{
    private readonly string _filePath;
    private readonly string _directory;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        Converters =
        {
            new JsonStringEnumConverter()
        }
    };

    public PersistenceService()
    {
        string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        _directory = Path.Combine(appData, "SurgSign");
        _filePath = Path.Combine(_directory, "patients.json");
    }

    public string FilePath => _filePath;

    /// <summary>
    /// Loads the patient list. Returns an empty list if the file does not exist
    /// or is unreadable (corruption is swallowed — this is a local-only prototype store).
    /// </summary>
    public List<Patient> Load()
    {
        try
        {
            if (!File.Exists(_filePath)) return new List<Patient>();

            using var stream = File.OpenRead(_filePath);
            var list = JsonSerializer.Deserialize<List<Patient>>(stream, JsonOptions);
            return list ?? new List<Patient>();
        }
        catch
        {
            return new List<Patient>();
        }
    }

    /// <summary>
    /// Saves the patient list atomically. Creates the data directory if missing.
    /// </summary>
    public void Save(IEnumerable<Patient> patients)
    {
        if (patients is null) throw new ArgumentNullException(nameof(patients));

        Directory.CreateDirectory(_directory);

        string tempPath = Path.Combine(_directory, "patients.tmp");

        var list = new List<Patient>(patients);
        using (var stream = File.Create(tempPath))
        {
            JsonSerializer.Serialize(stream, list, JsonOptions);
        }

        // Atomic replace.
        File.Move(tempPath, _filePath, overwrite: true);
    }
}
