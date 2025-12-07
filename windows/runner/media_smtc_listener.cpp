// media_smtc_listener.cpp
// WORKING SMTC LISTENER (NO THUMBNAIL: SMTC DOES NOT EXPOSE IT)
// Single-instance: only one process allowed at a time.

#include <windows.h>
#include <winrt/Windows.Media.Control.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.h>
#include <winrt/Windows.Media.Playback.h>

#include <mmdeviceapi.h>
#include <endpointvolume.h>

#include <iostream>
#include <string>
#include <thread>
#include <chrono>

using namespace winrt;
using namespace Windows::Foundation;
using namespace Windows::Media;
using namespace Windows::Media::Control;
using namespace Windows::Media::Playback;

// -------------------------------------------------------
// Simple peak helper (setup once)
// -------------------------------------------------------
class PeakMeter
{
public:
    PeakMeter()
    {
        CoInitialize(nullptr);

        HRESULT hr = CoCreateInstance(
            __uuidof(MMDeviceEnumerator),
            nullptr,
            CLSCTX_ALL,
            __uuidof(IMMDeviceEnumerator),
            reinterpret_cast<void **>(&enumerator_));

        if (FAILED(hr))
            return;

        hr = enumerator_->GetDefaultAudioEndpoint(
            eRender,
            eMultimedia,
            &device_);
        if (FAILED(hr))
            return;

        hr = device_->Activate(
            __uuidof(IAudioMeterInformation),
            CLSCTX_ALL,
            nullptr,
            reinterpret_cast<void **>(&meter_));
        if (FAILED(hr))
            return;

        ok_ = true;
    }

    ~PeakMeter()
    {
        if (meter_)
            meter_->Release();
        if (device_)
            device_->Release();
        if (enumerator_)
            enumerator_->Release();
        CoUninitialize();
    }

    float GetPeak() const
    {
        if (!ok_ || !meter_)
            return 0.0f;
        float peak = 0.0f;
        if (SUCCEEDED(meter_->GetPeakValue(&peak)))
        {
            return peak;
        }
        return 0.0f;
    }

private:
    bool ok_ = false;
    IMMDeviceEnumerator *enumerator_ = nullptr;
    IMMDevice *device_ = nullptr;
    IAudioMeterInformation *meter_ = nullptr;
};

// -------------------------------------------------------
// MAIN
// -------------------------------------------------------
int main()
{
    // =====================================================
    // 1) SINGLE INSTANCE GUARD (CORE FIX)
    // =====================================================
    // Global mutex name – should be unique to your app
    HANDLE hMutex = CreateMutexW(
        nullptr,
        FALSE,
        L"Global\\Alpha_MediaSmtcListener_Mutex");

    if (!hMutex)
    {
        // Could not create mutex, safe to just exit
        return 1;
    }

    // If another instance already created this mutex:
    if (GetLastError() == ERROR_ALREADY_EXISTS)
    {
        // Another listener is already running → exit quietly
        CloseHandle(hMutex);
        return 0;
    }

    // =====================================================
    // 2) NORMAL SMTC SETUP
    // =====================================================
    init_apartment();

    auto smtc = GlobalSystemMediaTransportControlsSessionManager::RequestAsync().get();
    auto session = smtc.GetCurrentSession();

    if (!session)
    {
        std::cout << "{\"title\":\"\",\"artist\":\"\",\"state\":\"Unknown\",\"peak\":0}" << std::endl;
        CloseHandle(hMutex);
        return 0;
    }

    session.PlaybackInfoChanged([](auto const &, auto const &) {});
    session.MediaPropertiesChanged([](auto const &, auto const &) {});

    PeakMeter peakMeter;

    while (true)
    {
        auto info = session.GetPlaybackInfo();
        auto props = session.TryGetMediaPropertiesAsync().get();

        std::string title = winrt::to_string(props.Title());
        std::string artist = winrt::to_string(props.Artist());

        std::string state;
        switch (info.PlaybackStatus())
        {
        case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing:
            state = "Playing";
            break;
        case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Paused:
            state = "Paused";
            break;
        case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Stopped:
            state = "Stopped";
            break;
        default:
            state = "Unknown";
        }

        // Timeline
        auto timeline = session.GetTimelineProperties();
        int64_t posMs = timeline.Position().count() / 10000;
        int64_t durMs = timeline.EndTime().count() / 10000;

        float peak = peakMeter.GetPeak();

        std::cout
            << "{"
            << "\"title\":\"" << title << "\","
            << "\"artist\":\"" << artist << "\","
            << "\"state\":\"" << state << "\","
            << "\"peak\":" << peak << ","
            << "\"position\":" << posMs << ","
            << "\"duration\":" << durMs << ","
            << "\"artwork\":\"\"" // still empty
            << "}"
            << std::endl;

        std::this_thread::sleep_for(std::chrono::milliseconds(250));
    }

    // Never really reached, but good practice:
    CloseHandle(hMutex);
    return 0;
}
