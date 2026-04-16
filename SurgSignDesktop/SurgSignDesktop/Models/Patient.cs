using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Text.Json.Serialization;

namespace SurgSignDesktop.Models;

/// <summary>
/// Core data model representing a surgical patient on the service list.
/// Mirrors the fields of the Swift <c>Patient</c> model.
/// </summary>
public class Patient : INotifyPropertyChanged
{
    private string _name = string.Empty;
    private string _mrn = string.Empty;
    private string _room = string.Empty;
    private string _surgeon = string.Empty;
    private string _diagnosis = string.Empty;
    private string _procedure = string.Empty;
    private DateTime? _surgeryDate;
    private CodeStatus _codeStatus = CodeStatus.FullCode;
    private string _allergies = string.Empty;
    private Priority _priority = Priority.Stable;
    private string _notes = string.Empty;
    private int _sortOrder;

    public Guid Id { get; set; } = Guid.NewGuid();

    public string Name
    {
        get => _name;
        set => SetField(ref _name, value);
    }

    public string Mrn
    {
        get => _mrn;
        set => SetField(ref _mrn, value);
    }

    public string Room
    {
        get => _room;
        set => SetField(ref _room, value);
    }

    public string Surgeon
    {
        get => _surgeon;
        set => SetField(ref _surgeon, value);
    }

    public string Diagnosis
    {
        get => _diagnosis;
        set => SetField(ref _diagnosis, value);
    }

    public string Procedure
    {
        get => _procedure;
        set => SetField(ref _procedure, value);
    }

    public DateTime? SurgeryDate
    {
        get => _surgeryDate;
        set
        {
            if (SetField(ref _surgeryDate, value))
            {
                OnPropertyChanged(nameof(PodLabel));
                OnPropertyChanged(nameof(PostOpDay));
            }
        }
    }

    public CodeStatus CodeStatus
    {
        get => _codeStatus;
        set => SetField(ref _codeStatus, value);
    }

    public string Allergies
    {
        get => _allergies;
        set => SetField(ref _allergies, value);
    }

    public Priority Priority
    {
        get => _priority;
        set => SetField(ref _priority, value);
    }

    public string Notes
    {
        get => _notes;
        set => SetField(ref _notes, value);
    }

    public int SortOrder
    {
        get => _sortOrder;
        set => SetField(ref _sortOrder, value);
    }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ObservableCollection<PatientTask> Tasks { get; set; } = new();

    // MARK: - Computed Properties

    /// <summary>Post-operative day from <see cref="SurgeryDate"/>, or <c>null</c> if not set.</summary>
    [JsonIgnore]
    public int? PostOpDay => PODCalculator.Calculate(SurgeryDate);

    /// <summary>Human-readable POD label such as <c>"Pre-Op"</c>, <c>"POD 0"</c>, <c>"POD 3"</c>.</summary>
    [JsonIgnore]
    public string? PodLabel => PODCalculator.Label(SurgeryDate);

    /// <summary>Number of pending (incomplete) tasks.</summary>
    [JsonIgnore]
    public int PendingTaskCount
    {
        get
        {
            int count = 0;
            foreach (var t in Tasks)
            {
                if (!t.IsDone) count++;
            }
            return count;
        }
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    protected void OnPropertyChanged([CallerMemberName] string? name = null) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));

    private bool SetField<T>(ref T field, T value, [CallerMemberName] string? name = null)
    {
        if (Equals(field, value)) return false;
        field = value;
        OnPropertyChanged(name);
        return true;
    }
}
