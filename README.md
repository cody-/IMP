#IMP
Adium Incoming Message Preprocessor plugin.

###Installation
Clone this repo:
```
git clone https://github.com/cody-/IMP.git
cd IMP
```

Clone and build adium:
```
git clone -b adium-1.5.9 https://github.com/adium/adium
cd adium
make adium
```
Note that you should clone branch related to your version of Adium

Open Xcode project:
```
open IMP.xcodeproj
```
Run via `Cmd` + `R`

###Configuration
After installation there will be directory `~/Library/Application Suport/Adium IMP/scripts`.<br />
Just place there some script, name it via contact UID and make it executable.<br />
Original message will be passed to that script as first argument, stdout will be printed to chat window.<br />
In case of some error stderr will be printed with original message. Note that IMP ignores script exit code, it just checks stderr.

###Example
You can debug your scripts by sending message to yourself.<br />
Lets pretend that your UID is `me@gmail.com`. Add it to your contact list.

Now create script for that contact:
```
touch ~/Library/Application\ Suport/Adium\ IMP/scripts/me@gmail.com
chmod +x ~/Library/Application\ Suport/Adium\ IMP/scripts/me@gmail.com
```

Add some logic to script:
```
#!/bin/bash
msg=$1
echo "Hello ${msg}!"
```

Now send to `me@gmail.com` message `world`, you should receive `Hello world!`
