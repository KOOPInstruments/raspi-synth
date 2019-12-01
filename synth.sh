## Raspberry Pi 4 FluidSynth MIDI Sound Engine
## 2019 - KOOP Instruments (koopinstruments@gmail.com) 

# Remount the file system read/write to allow modifications
sudo mount -o remount,rw /

# Update the clock
sudo ntpd -q -g

echo "Starting synth script in 5 seconds (press Ctrl-c to cancel)..."
sleep 1
echo "4..."
sleep 1
echo "3..."
sleep 1
echo "2..."
sleep 1
echo "1..."
sleep 1

# If the script was not cancelled, remount the file system readonly
sudo mount -o remount,r /

## Optional power saving (uncomment if desired):
# sudo ifconfig wlan0 down  # Disable the Wi-Fi adapter
sudo tvservice --off  # Disable HDMI video output

echo "Killing any existing fluidsynth processes..."

sudo killall -s SIGKILL fluidsynth &>/dev/null

# Run the rest of the script on a loop in case a new sound card is connected, the FluidSynth server crashes, or a new MIDI instrument is connected
while [[ 1 -eq 1 ]]; do

    # Run 'cat /proc/asound/cards' to get a list of audio devices, and modify the grep statement below with a unique identifying string
    # Examples:
    # audioDevice=$(cat /proc/asound/cards | grep "bcm2835_alsa" | awk -F" " '{ print $1 }')  # Raspberry Pi on-board audio (high latency - only use if no other options)
    # audioDevice=$(cat /proc/asound/cards | grep "USB-Audio - USB Audio Device" | awk -F" " '{ print $1 }')  # Sabrent USB sound card
    # audioDevice=$(cat /proc/asound/cards | grep "USB-Audio - Logitech" | awk -F" " '{ print $1 }')  # Logitech USB sound card

    audioDevice=$(cat /proc/asound/cards | grep "USB-Audio - USB AUDIO" | awk -F" " '{ print $1 }')  # Peavy USB mixer sound card

    if pgrep -x "fluidsynth" > /dev/null
    then
        sleep 1
    else
        echo "Starting fluidsynth server..."
        # Blink both lights to let the user know that the synth is starting
        sudo echo 1 | sudo tee /sys/class/leds/led0/brightness &>/dev/null
        sudo echo 1 | sudo tee /sys/class/leds/led1/brightness &>/dev/null
        sudo echo 0 | sudo tee /sys/class/leds/led0/brightness &>/dev/null
        sudo echo 0 | sudo tee /sys/class/leds/led1/brightness &>/dev/null
        sudo echo 1 | sudo tee /sys/class/leds/led0/brightness &>/dev/null
        sudo echo 1 | sudo tee /sys/class/leds/led1/brightness &>/dev/null
        sudo echo 0 | sudo tee /sys/class/leds/led0/brightness &>/dev/null
        sudo echo 0 | sudo tee /sys/class/leds/led1/brightness &>/dev/null
        sudo echo 1 | sudo tee /sys/class/leds/led0/brightness &>/dev/null
        sudo echo 1 | sudo tee /sys/class/leds/led1/brightness &>/dev/null
        sudo echo 0 | sudo tee /sys/class/leds/led0/brightness &>/dev/null
        sudo echo 0 | sudo tee /sys/class/leds/led1/brightness &>/dev/null
        # Start the FluidSynth server in a new screen session to allow reattaching for troubleshooting purposes
        screen -dmS FluidSynth0 bash -c "sudo nice -n -20 fluidsynth -i -s -g 0.6 -a alsa -o audio.alsa.device=hw:$audioDevice -c 1 -z 1 -o synth.cpu-cores=4 -o synth.polyphony=128 /usr/share/sounds/sf2/FluidR3_GM.sf2"
        sleep 5
    fi

    # Scrape the ALSA port number of the FluidSynth Server
    fsClientNum=$(aconnect -l | grep "FLUID Synth" | awk -F" " '{ print $2 -0 }')

    # Enable one light to let the user know that device discovery is running
    echo 1 | sudo tee /sys/class/leds/led1/brightness &>/dev/null

    myCounter=1

    while [[ $myCounter -lt $fsClientNum ]]; do
        aconnect $myCounter:0 $fsClientNum:0 2>/dev/null
        let myCounter=myCounter+1
    done

    echo 0 | sudo tee /sys/class/leds/led1/brightness &>/dev/null

    sleep 1

done
