using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace SurgSignDesktop.Models;

/// <summary>
/// A discrete task (to-do item) associated with a patient during a shift handoff.
/// </summary>
public class PatientTask : INotifyPropertyChanged
{
    private string _text = string.Empty;
    private bool _isDone;
    private int _sortOrder;

    public Guid Id { get; set; } = Guid.NewGuid();

    public string Text
    {
        get => _text;
        set => SetField(ref _text, value);
    }

    public bool IsDone
    {
        get => _isDone;
        set => SetField(ref _isDone, value);
    }

    public int SortOrder
    {
        get => _sortOrder;
        set => SetField(ref _sortOrder, value);
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    protected void OnPropertyChanged([CallerMemberName] string? name = null) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));

    private void SetField<T>(ref T field, T value, [CallerMemberName] string? name = null)
    {
        if (Equals(field, value)) return;
        field = value;
        OnPropertyChanged(name);
    }
}
