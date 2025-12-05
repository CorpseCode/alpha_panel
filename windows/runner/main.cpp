// windows/runner/main.cpp
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <windows.h>
#include <shellapi.h>

#include "flutter_window.h"
#include "utils.h"

// =====================================================
// Auto-elevation utilities
// =====================================================

bool IsProcessElevated()
{
  HANDLE token = NULL;
  TOKEN_ELEVATION elevation;
  DWORD size;

  if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token))
    return false;

  bool result = false;
  if (GetTokenInformation(token, TokenElevation, &elevation, sizeof(elevation), &size))
    result = elevation.TokenIsElevated != 0;

  CloseHandle(token);
  return result;
}

// Relaunch elevated, used only when NOT in debug mode
void RelaunchAsAdmin()
{
  wchar_t exePath[MAX_PATH];
  GetModuleFileNameW(NULL, exePath, MAX_PATH);

  ShellExecuteW(
      NULL,
      L"runas",
      exePath,
      NULL,
      NULL,
      SW_SHOWNORMAL);

  ExitProcess(0); // terminate non-admin instance properly
}

int APIENTRY wWinMain(_In_ HINSTANCE instance,
                      _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line,
                      _In_ int show_command)
{
  // ==========================================================
  // AUTO-ELEVATION (Release Only)
  // ==========================================================
#if !defined(_DEBUG)
  if (!IsProcessElevated())
  {
    RelaunchAsAdmin();
  }
#endif

  // ==========================================================
  // NORMAL DEBUG FLOW (NO AUTO ELEVATION)
  // ==========================================================
#if defined(_DEBUG)
  // Attach console for flutter run
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent())
  {
    CreateAndAttachConsole();
  }
#endif

  // Initialize COM
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // position + size of your panel
  Win32Window::Point origin(100, 100);
  Win32Window::Size size(450, 700);

  if (!window.Create(L"alpha", origin, size))
  {
    return EXIT_FAILURE;
  }

  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0))
  {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
