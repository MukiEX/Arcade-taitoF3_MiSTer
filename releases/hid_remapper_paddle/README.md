# Taito Egret II Mini Paddle Trackball Controller Remap
# For Taito F3 MiSTer Core

## Hardware

To use this file you will need a Pi Pico device with USB host. The easy cheap option is the Waveshare RP2350A that's like $12 on Amazon (or $5 per adapter on the Waveshare website if you don't mind paying $10 for shipping and waiting a bit longer; I ordered 6 adapters myself). The HID remapper website lists many other options, some sold through partners. You may also need a normal gamepad to map things (see below)

## What this is

This is an HID Remapper configuration for turning an Egret II Mini Paddle into an F3 Spinner controller using the JP3 toggle in this core.

This is done by sending the left/right rotary encoder signals through a USB Switch controller setting.

Unfortunately, **pressing left and right at the same time is not allowed by the Linux Switch controller driver**. So you'll want to first plug a regular controller into the HID remapper dongle and set the buttons. While HID remapper will properly remap most PC gamepads to their Switch equivalent buttons accurately, you'll probably wanna use the Gamepad Tester website to make sure it's set right, especially for the left and right stick clicks.

Use these mapping settings:

- Left - LS / L3
- Right - LS / R3
- Up / Down - Up / Down on d-pad (you won't use this)
- Button 1/Button 2 - A/B on the controller
- Start/Coin - Plus/Minus on the controller
- Service - Home button

After that's done:

1. Open the MiSTer OSD while in the PuchiCarat core and set "Spinner (JP3)" to "On"
2. Open the MiSTer OSD and enable "Service Mode" after the "Please Wait" sequence is over. This will put you in the Service menu.
2. Press button 1 or 2 to move down and go to "Configuration"
3. Set Device to "Sensor", go down to "Exit", and save data.
4. Go down to "Switch Test".
5. **You may need to reset player assignments so that each paddle controller gets assigned as 1st and 2nd player**
6. If you configured things right, turning the knob on the Egret Mini Paddle controller will slowly increase and decrease the sensor value. If it moves randomly or gets stuck between extremes, something is wrong.

## The advantage versus just setting up mouse support

Linux doesn't support multiple mice very well. Every solution is hacky; the actual MAME core sets each player to a different mouse axis, for example.

However, it does support multiple controllers pretty easily. As such, all you need
