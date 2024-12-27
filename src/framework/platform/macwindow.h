#pragma once
#include "platformwindow.h"

class MacWindow : public PlatformWindow
{
public:
    MacWindow() {}
    ~MacWindow() override = default;

    bool initWindow(const std::string& title, int width, int height, bool fullscreen) override { return false; }
    void pollEvents() override {}
    void swapBuffers() override {}
    ...
    // etc. Just no-op or stub out everything.
};
