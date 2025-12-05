// media_smtc_listener.cpp
// WORKING SMTC LISTENER (NO THUMBNAIL: SMTC DOES NOT EXPOSE IT)

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
using namespace Windows::Storage::Streams;
using namespace Windows::Graphics::Imaging;

// -------------------------------------------------------
// Get WASAPI peak (0.0 - 1.0)
// -------------------------------------------------------
float GetPeak()
{
    CoInitialize(nullptr);

    IMMDeviceEnumerator *enumerator = nullptr;
    if (FAILED(CoCreateInstance(
            __uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
            __uuidof(IMMDeviceEnumerator), (void **)&enumerator)))
        return 0.0f;

    IMMDevice *device = nullptr;
    if (FAILED(enumerator->GetDefaultAudioEndpoint(eRender, eMultimedia, &device)))
        return 0.0f;

    IAudioMeterInformation *meter = nullptr;
    if (FAILED(device->Activate(__uuidof(IAudioMeterInformation),
                                CLSCTX_ALL, nullptr, (void **)&meter)))
        return 0.0f;

    float peak = 0.0f;
    meter->GetPeakValue(&peak);

    meter->Release();
    device->Release();
    enumerator->Release();
    CoUninitialize();

    return peak;
}

// -------------------------------------------------------
// MAIN
// -------------------------------------------------------
int main()
{
    init_apartment();

    auto smtc = GlobalSystemMediaTransportControlsSessionManager::RequestAsync().get();
    auto session = smtc.GetCurrentSession();

    if (!session)
    {
        std::cout << "{\"title\":\"\",\"artist\":\"\",\"state\":\"Unknown\",\"peak\":0}" << std::endl;
        return 0;
    }

    session.PlaybackInfoChanged([](auto const &, auto const &) {});
    session.MediaPropertiesChanged([](auto const &, auto const &) {});

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

        // SMTC DOES NOT PROVIDE ARTWORK
        std::string artwork = "";

        float peak = GetPeak();

        std::cout
            << "{"
            << "\"title\":\"" << title << "\","
            << "\"artist\":\"" << artist << "\","
            << "\"state\":\"" << state << "\","
            << "\"peak\":" << peak << ","
            << "\"position\":" << posMs << ","
            << "\"duration\":" << durMs << ","
            << "\"artwork\":\"\"" // always empty for now
            << "}"
            << std::endl;

        std::this_thread::sleep_for(std::chrono::milliseconds(250));
    }

    return 0;
}
