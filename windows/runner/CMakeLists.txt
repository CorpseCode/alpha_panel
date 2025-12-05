cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# ============================================================
# GLOBAL C++ SETTINGS (REQUIRED FOR WINRT)
# ============================================================
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_definitions(-DWINVER=0x0A00)
add_definitions(-D_WIN32_WINNT=0x0A00)

# ============================================================
# MAIN RUNNER EXECUTABLE
# ============================================================
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# WinRT & flutter
target_link_libraries(${BINARY_NAME} PRIVATE
    flutter
    flutter_wrapper_app
    windowsapp               # REQUIRED FOR WINRT
    dwmapi.lib
)

# WinRT include dirs
target_include_directories(${BINARY_NAME} PRIVATE
    "$ENV{WindowsSdkDir}/Include/$ENV{WindowsSDKVersion}/winrt"
    "${CMAKE_SOURCE_DIR}"
)

add_dependencies(${BINARY_NAME} flutter_assemble)




# ============================================================
# SMTC LISTENER EXECUTABLE  (OUTPUT → PROJECT ROOT)
# ============================================================
add_executable(media_smtc_listener
  "${CMAKE_CURRENT_SOURCE_DIR}/media_smtc_listener.cpp"
)

target_compile_features(media_smtc_listener PRIVATE cxx_std_20)

# WinRT + COM
target_link_libraries(media_smtc_listener PRIVATE
    windowsapp
    ole32
)

# 1️⃣ OUTPUT compiled SMTC exe to project root
set_target_properties(media_smtc_listener PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}"
)

# 2️⃣ ALSO COPY it beside runner.exe (for release/distribution)
add_custom_command(
  TARGET media_smtc_listener POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy
      $<TARGET_FILE:media_smtc_listener>
      "${CMAKE_BINARY_DIR}/runner"
)

# Ensure it builds before main runner
add_dependencies(${BINARY_NAME} media_smtc_listener)
