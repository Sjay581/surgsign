using System.Collections.Generic;
using System.Globalization;
using System.Text;
using System.Windows.Media.Imaging;
using SurgSignDesktop.Models;
using SurgSignDesktop.Services;

namespace SurgSignDesktop.ViewModels;

/// <summary>
/// Builds the handoff QR code for a set of patients and exposes it as a <see cref="BitmapSource"/>.
/// </summary>
public class HandoffViewModel : ObservableObject
{
    private BitmapSource? _qrImage;
    private string _qrPayloadString = string.Empty;
    private int _payloadSize;
    private int _jsonSize;
    private int _patientCount;
    private string _serviceName = string.Empty;
    private string _shift = "AM";

    public HandoffViewModel(IEnumerable<PatientViewModel> patients, string serviceName, string shift)
    {
        _serviceName = serviceName;
        _shift = shift;
        Build(patients, serviceName, shift);
    }

    public BitmapSource? QrImage
    {
        get => _qrImage;
        private set => SetProperty(ref _qrImage, value);
    }

    public string QrPayloadString
    {
        get => _qrPayloadString;
        private set => SetProperty(ref _qrPayloadString, value);
    }

    public int PayloadSize
    {
        get => _payloadSize;
        private set => SetProperty(ref _payloadSize, value);
    }

    public int JsonSize
    {
        get => _jsonSize;
        private set => SetProperty(ref _jsonSize, value);
    }

    public int PatientCount
    {
        get => _patientCount;
        private set => SetProperty(ref _patientCount, value);
    }

    public string ServiceName => _serviceName;
    public string Shift => _shift;

    public string Summary =>
        $"{PatientCount} patient{(PatientCount == 1 ? string.Empty : "s")}  •  QR payload {PayloadSize} bytes  •  JSON {JsonSize} bytes";

    private void Build(IEnumerable<PatientViewModel> patients, string serviceName, string shift)
    {
        var payload = new TransferPayload
        {
            V = 2,
            Svc = serviceName ?? string.Empty,
            From = shift ?? "AM",
            Pts = new List<PatientDTO>()
        };

        int count = 0;
        foreach (var vm in patients)
        {
            payload.Pts.Add(BuildPatientDto(vm.Model));
            count++;
        }
        PatientCount = count;

        string qrString = CompressionService.Encode(payload);
        QrPayloadString = qrString;
        PayloadSize = Encoding.UTF8.GetByteCount(qrString);
        JsonSize = Encoding.UTF8.GetByteCount(CompressionService.SerializeJson(payload));

        QrImage = QrGenerator.Generate(qrString, QRCoder.QRCodeGenerator.ECCLevel.M, pixelsPerModule: 8);
        OnPropertyChanged(nameof(Summary));
    }

    private static PatientDTO BuildPatientDto(Patient patient)
    {
        var dto = new PatientDTO
        {
            Id = patient.Id.ToString(),
            N = patient.Name ?? string.Empty,
            M = patient.Mrn ?? string.Empty,
            R = patient.Room ?? string.Empty,
            S = patient.Surgeon ?? string.Empty,
            Dx = patient.Diagnosis ?? string.Empty,
            Px = patient.Procedure ?? string.Empty,
            Sd = FormatDate(patient.SurgeryDate),
            Cs = patient.CodeStatus.RawValue(),
            Al = patient.Allergies ?? string.Empty,
            Pr = patient.Priority.RawValue(),
            Nt = patient.Notes ?? string.Empty,
            Is = new List<TaskDTO>()
        };

        foreach (var t in patient.Tasks)
        {
            dto.Is.Add(new TaskDTO
            {
                Id = t.Id.ToString(),
                T = t.Text ?? string.Empty,
                D = t.IsDone ? 1 : 0
            });
        }
        return dto;
    }

    /// <summary>
    /// Matches Swift's <c>ISO8601DateFormatter().withInternetDateTime</c> — no fractional seconds.
    /// </summary>
    private static string FormatDate(System.DateTime? date)
    {
        if (date is null) return string.Empty;
        var utc = date.Value.Kind == System.DateTimeKind.Utc
            ? date.Value
            : date.Value.ToUniversalTime();
        return utc.ToString("yyyy-MM-ddTHH:mm:ssZ", CultureInfo.InvariantCulture);
    }
}
