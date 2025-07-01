cmake_minimum_required(VERSION 3.14)
project(tapem LANGUAGES CXX)

# === Standard-Settings für alle Targets ===
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  # nur /W4, kein /WX, damit Deprecation-Warnings nicht zu Errors werden
  target_compile_options(${TARGET} PRIVATE /W4 /wd4100)
  target_compile_options(${TARGET} PRIVATE /EHsc)
endfunction()

# Flutter-Managed Code
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Dein Windows Runner
add_subdirectory("runner")

# Plugins registrieren
include(flutter/generated_plugins.cmake)
