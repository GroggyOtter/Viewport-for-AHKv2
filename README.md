# Viewport for AHK v2

A script I threw together that allows you to createa a viewport.  
Meaning it blacks out the screen but keeps a section of screen visible.  
You can interact with things inside the viewport.

[`Demo`](https://i.imgur.com/HmqTXxu.mp4)

## Controls
Controls can be set customized by editing the `keys` map.  

Use standard [AHK hotkey notation](https://www.autohotkey.com/docs/v2/Hotkeys.htm).  
Example: Ctrl+F1 would be `^F1` and Win+NumpadAdd is `#NumpadAdd`.  

### Default controls:

* Shift+F1: Activate/Deactivate  
Activate/deactivate viewport hotkeys.

* Shift+LButton: Make/Move Viewport  
Click and drag to make a new viewport.  
If mouse is on a viewport, click and drag to move.

* Shift+MButton: Toggle Viewport Overlay  
Toggle viewport overlay.

* Shift+RButton:  Resize Viewport  
Drag right/left to increase/decrease viewport width respectively.  
Same with up/down to increase/decrease viewport height.

* Shift+WheelUp/WheelDown: Adjust GUI Alpha  
Increases/decreases alpha value of the main GUI to a value between 0 (fully transparent) and 255 (fully opaque).  
