// windows/runner/flutter_window.cpp
#include "flutter_window.h"

#include <dwmapi.h>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

#pragma comment(lib, "Dwmapi.lib")

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate()
{
  if (!Win32Window::OnCreate())
  {
    return false;
  }

  // Get the HWND from the base Win32Window
  HWND hwnd = GetHandle();
  if (!hwnd)
  {
    return false;
  }

  // Remove standard chrome and make layered; keep it clickable by not using HTTRANSPARENT.
  LONG style = GetWindowLong(hwnd, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
  SetWindowLong(hwnd, GWL_STYLE, style);

  LONG exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
  // WS_EX_TOOLWINDOW hides from taskbar; WS_EX_LAYERED enables per-pixel alpha compositing
  exStyle |= (WS_EX_LAYERED | WS_EX_TOOLWINDOW | WS_EX_NOREDIRECTIONBITMAP);
  SetWindowLong(hwnd, GWL_EXSTYLE, exStyle);

  // Ensure DWM extends frame so the client is fully composited and can be transparent.
  MARGINS margins = {-1};
  DwmExtendFrameIntoClientArea(hwnd, &margins);

  // Set layered attributes (alpha = 255 keeps full opacity for painted pixels, but allows alpha channel)
  SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA);

  RECT frame = GetClientArea();

  // Create Flutter controller with client size
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view())
  {
    return false;
  }

  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->ForceRedraw();
  this->Show(); // force window visible even if no Flutter frame yet

  return true;
}

void FlutterWindow::OnDestroy()
{
  if (flutter_controller_)
  {
    flutter_controller_ = nullptr;
  }
  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                                      WPARAM const wparam, LPARAM const lparam) noexcept
{
  // Let Flutter, including plugins, handle messages first.
  if (flutter_controller_)
  {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
    if (result)
    {
      return *result;
    }
  }

  switch (message)
  {
  case WM_NCCALCSIZE:
    // Remove non-client area so we are fully frameless.
    return 0;

  case WM_NCHITTEST:
    // Provide client area hit test so Flutter receives mouse events.
    // Returning HTCLIENT ensures clicks go to the client (Flutter) and not be treated like titlebar.
    return HTCLIENT;

  case WM_DPICHANGED:
  {
    // Let base class handle resizing and child layout
    break;
  }

  case WM_FONTCHANGE:
    if (flutter_controller_ && flutter_controller_->engine())
    {
      flutter_controller_->engine()->ReloadSystemFonts();
    }
    break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
