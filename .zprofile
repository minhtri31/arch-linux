### 🗣️ Input Method (Fcitx5)
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export INPUT_METHOD=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=fcitx

### 🎨 Theme & Portal
#export GTK_THEME=Catppuccin-Dark

### 💻 GPU Intel Haswell (HD 4400)
export LIBVA_DRIVER_NAME=i965
export VDPAU_DRIVER=va_gl

### 🌈 SwayFX / wlroots tuning
export WLR_RENDERER=vulkan             # Chuyển thành 'gles2' nếu Vulkan bị crash
export WLR_NO_HARDWARE_CURSORS=1       # Fix lỗi hiển thị chuột
export WLR_BACKENDS=libinput,drm
# export WLR_DRM_NO_ATOMIC=1           # Mở nếu bị lỗi hotplug màn hình

### 🌐 Electron / Chrome / Firefox / Qt
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export ELECTRON_OZONE_PLATFORM_HINT=auto


