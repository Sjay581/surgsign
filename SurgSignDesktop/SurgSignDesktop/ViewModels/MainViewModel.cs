using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Windows;
using SurgSignDesktop.Models;
using SurgSignDesktop.Services;

namespace SurgSignDesktop.ViewModels;

/// <summary>
/// Root view-model for the main window. Owns the patient collection, selection,
/// and the service / shift metadata used to build the handoff QR.
/// </summary>
public class MainViewModel : ObservableObject
{
    private readonly PersistenceService _persistence;
    private PatientViewModel? _selectedPatient;
    private string _serviceName = "General Surgery";
    private string _shift = "AM";
    private bool _suppressSave;

    public MainViewModel() : this(new PersistenceService()) { }

    public MainViewModel(PersistenceService persistence)
    {
        _persistence = persistence ?? throw new ArgumentNullException(nameof(persistence));

        Patients = new ObservableCollection<PatientViewModel>();

        AddPatientCommand = new RelayCommand(AddPatient);
        DeletePatientCommand = new RelayCommand(DeleteSelectedPatient, () => SelectedPatient is not null);
        HandoffCommand = new RelayCommand(ShowHandoff, () => Patients.Count > 0);
        ToggleAmCommand = new RelayCommand(() => { Shift = "AM"; });
        TogglePmCommand = new RelayCommand(() => { Shift = "PM"; });
        AddTaskCommand = new RelayCommand(AddTaskToSelected, () => SelectedPatient is not null);
        RemoveTaskCommand = new RelayCommand(RemoveTask, p => p is PatientTask && SelectedPatient is not null);

        LoadFromDisk();

        Patients.CollectionChanged += (_, _) =>
        {
            (HandoffCommand as RelayCommand)?.RaiseCanExecuteChanged();
            SaveToDisk();
        };
    }

    public ObservableCollection<PatientViewModel> Patients { get; }

    public PatientViewModel? SelectedPatient
    {
        get => _selectedPatient;
        set
        {
            if (_selectedPatient is not null)
                _selectedPatient.PropertyChanged -= OnSelectedPatientChanged;

            if (SetProperty(ref _selectedPatient, value))
            {
                (DeletePatientCommand as RelayCommand)?.RaiseCanExecuteChanged();
                (AddTaskCommand as RelayCommand)?.RaiseCanExecuteChanged();
                (RemoveTaskCommand as RelayCommand)?.RaiseCanExecuteChanged();
                if (_selectedPatient is not null)
                    _selectedPatient.PropertyChanged += OnSelectedPatientChanged;
            }
        }
    }

    public string ServiceName
    {
        get => _serviceName;
        set
        {
            if (SetProperty(ref _serviceName, value ?? string.Empty)) SaveToDisk();
        }
    }

    public string Shift
    {
        get => _shift;
        set
        {
            if (SetProperty(ref _shift, value ?? "AM"))
            {
                OnPropertyChanged(nameof(IsAm));
                OnPropertyChanged(nameof(IsPm));
                SaveToDisk();
            }
        }
    }

    public bool IsAm => _shift == "AM";
    public bool IsPm => _shift == "PM";

    public System.Windows.Input.ICommand AddPatientCommand { get; }
    public System.Windows.Input.ICommand DeletePatientCommand { get; }
    public System.Windows.Input.ICommand HandoffCommand { get; }
    public System.Windows.Input.ICommand ToggleAmCommand { get; }
    public System.Windows.Input.ICommand TogglePmCommand { get; }
    public System.Windows.Input.ICommand AddTaskCommand { get; }
    public System.Windows.Input.ICommand RemoveTaskCommand { get; }

    public bool HasPatients => Patients.Count > 0;

    private void AddPatient()
    {
        var patient = new Patient
        {
            Name = "New Patient",
            Mrn = string.Empty,
            SortOrder = Patients.Count,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        var vm = new PatientViewModel(patient);
        Patients.Add(vm);
        SelectedPatient = vm;
        OnPropertyChanged(nameof(HasPatients));
    }

    private void DeleteSelectedPatient()
    {
        if (SelectedPatient is null) return;

        var result = MessageBox.Show(
            $"Delete patient \"{SelectedPatient.Name}\"? This cannot be undone.",
            "Confirm Delete",
            MessageBoxButton.OKCancel,
            MessageBoxImage.Warning);
        if (result != MessageBoxResult.OK) return;

        Patients.Remove(SelectedPatient);
        SelectedPatient = Patients.FirstOrDefault();
        OnPropertyChanged(nameof(HasPatients));
    }

    private void AddTaskToSelected()
    {
        if (SelectedPatient is null) return;
        var task = new PatientTask
        {
            Text = string.Empty,
            IsDone = false,
            SortOrder = SelectedPatient.Tasks.Count
        };
        task.PropertyChanged += (_, _) =>
        {
            SelectedPatient?.NotifyDerivedChanged();
            SaveToDisk();
        };
        SelectedPatient.Tasks.Add(task);
        SelectedPatient.NotifyDerivedChanged();
        SaveToDisk();
    }

    private void RemoveTask(object? parameter)
    {
        if (SelectedPatient is null || parameter is not PatientTask task) return;
        SelectedPatient.Tasks.Remove(task);
        SelectedPatient.NotifyDerivedChanged();
        SaveToDisk();
    }

    private void ShowHandoff()
    {
        if (Patients.Count == 0) return;
        var handoff = new HandoffViewModel(Patients, ServiceName, Shift);
        var window = new Views.HandoffWindow
        {
            DataContext = handoff,
            Owner = Application.Current?.MainWindow
        };
        window.ShowDialog();
    }

    private void OnSelectedPatientChanged(object? sender, PropertyChangedEventArgs e) =>
        SaveToDisk();

    private void LoadFromDisk()
    {
        _suppressSave = true;
        try
        {
            var loaded = _persistence.Load();
            foreach (var p in loaded.OrderBy(p => p.SortOrder).ThenBy(p => p.CreatedAt))
            {
                var vm = new PatientViewModel(p);
                foreach (var task in p.Tasks)
                {
                    task.PropertyChanged += (_, _) =>
                    {
                        vm.NotifyDerivedChanged();
                        SaveToDisk();
                    };
                }
                Patients.Add(vm);
            }
            OnPropertyChanged(nameof(HasPatients));
        }
        finally
        {
            _suppressSave = false;
        }
    }

    private void SaveToDisk()
    {
        if (_suppressSave) return;
        try
        {
            _persistence.Save(Patients.Select(vm => vm.Model));
        }
        catch (Exception ex)
        {
            // Intentionally swallow — the prototype should not crash on a write failure.
            System.Diagnostics.Debug.WriteLine($"Save failed: {ex.Message}");
        }
    }
}
