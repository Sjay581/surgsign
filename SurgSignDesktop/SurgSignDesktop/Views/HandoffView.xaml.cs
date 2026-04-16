using System.Windows;
using SurgSignDesktop.ViewModels;

namespace SurgSignDesktop.Views;

/// <summary>
/// Interaction logic for HandoffView.xaml.
/// </summary>
public partial class HandoffWindow : Window
{
    public HandoffWindow()
    {
        InitializeComponent();
    }

    private void OnDoneClicked(object sender, RoutedEventArgs e) => Close();

    private void OnCopyClicked(object sender, RoutedEventArgs e)
    {
        if (DataContext is HandoffViewModel vm && !string.IsNullOrEmpty(vm.QrPayloadString))
        {
            try
            {
                Clipboard.SetText(vm.QrPayloadString);
            }
            catch
            {
                // Clipboard can occasionally throw under RDP / lock screen — ignore.
            }
        }
    }
}
