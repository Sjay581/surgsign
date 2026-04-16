using System;
using System.Collections.ObjectModel;
using SurgSignDesktop.Models;

namespace SurgSignDesktop.ViewModels;

/// <summary>
/// Wraps a <see cref="Patient"/> for data-binding in list and edit views.
/// </summary>
public class PatientViewModel : ObservableObject
{
    public PatientViewModel(Patient patient)
    {
        Model = patient ?? throw new ArgumentNullException(nameof(patient));
    }

    public Patient Model { get; }

    public Guid Id => Model.Id;

    public string Name
    {
        get => Model.Name;
        set
        {
            if (Model.Name == value) return;
            Model.Name = value;
            Model.UpdatedAt = DateTime.UtcNow;
            OnPropertyChanged();
        }
    }

    public string Mrn
    {
        get => Model.Mrn;
        set { if (Model.Mrn == value) return; Model.Mrn = value; Model.UpdatedAt = DateTime.UtcNow; OnPropertyChanged(); }
    }

    public string Room
    {
        get => Model.Room;
        set { if (Model.Room == value) return; Model.Room = value; Model.UpdatedAt = DateTime.UtcNow; OnPropertyChanged(); }
    }

    public string Surgeon
    {
        get => Model.Surgeon;
        set { if (Model.Surgeon == value) return; Model.Surgeon = value; Model.UpdatedAt = DateTime.UtcNow; OnPropertyChanged(); }
    }

    public string Diagnosis
    {
        get => Model.Diagnosis;
        set { if (Model.Diagnosis == value) return; Model.Diagnosis = value; Model.UpdatedAt = DateTime.UtcNow; OnPropertyChanged(); }
    }

    public string Procedure
    {
        get => Model.Procedure;
        set { if (Model.Procedure == value) return; Model.Procedure = value; Model.UpdatedAt = DateTime.UtcNow; OnPropertyChanged(); }
    }

    public DateTime? SurgeryDate
    {
        get => Model.SurgeryDate;
        set
        {
            if (Model.SurgeryDate == value) return;
            Model.SurgeryDate = value;
            Model.UpdatedAt = DateTime.UtcNow;
            OnPropertyChanged();
            OnPropertyChanged(nameof(PodLabel));
        }
    }

    public CodeStatus CodeStatus
    {
        get => Model.CodeStatus;
        set
        {
            if (Model.CodeStatus == value) return;
            Model.CodeStatus = value;
            Model.UpdatedAt = DateTime.UtcNow;
            OnPropertyChanged();
            OnPropertyChanged(nameof(CodeStatusLabel));
        }
    }

    public string CodeStatusLabel => Model.CodeStatus.ShortLabel();

    public string Allergies
    {
        get => Model.Allergies;
        set { if (Model.Allergies == value) return; Model.Allergies = value; Model.UpdatedAt = DateTime.UtcNow; OnPropertyChanged(); }
    }

    public Priority Priority
    {
        get => Model.Priority;
        set
        {
            if (Model.Priority == value) return;
            Model.Priority = value;
            Model.UpdatedAt = DateTime.UtcNow;
            OnPropertyChanged();
            OnPropertyChanged(nameof(PriorityLabel));
        }
    }

    public string PriorityLabel => Model.Priority.Label();

    public string Notes
    {
        get => Model.Notes;
        set { if (Model.Notes == value) return; Model.Notes = value; Model.UpdatedAt = DateTime.UtcNow; OnPropertyChanged(); }
    }

    public string? PodLabel => Model.PodLabel;

    public int PendingTaskCount => Model.PendingTaskCount;

    public ObservableCollection<PatientTask> Tasks => Model.Tasks;

    /// <summary>
    /// Re-raise notifications so the list view refreshes after edits
    /// (including task changes which don't bubble automatically).
    /// </summary>
    public void NotifyDerivedChanged()
    {
        OnPropertyChanged(nameof(PendingTaskCount));
        OnPropertyChanged(nameof(PodLabel));
        OnPropertyChanged(nameof(PriorityLabel));
        OnPropertyChanged(nameof(CodeStatusLabel));
    }
}
