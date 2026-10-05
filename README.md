# SimpleFPS
<img width="510" height="680" alt="image" src="https://github.com/user-attachments/assets/1f62bce6-df23-4b37-8c7f-b669290ebb9f" />

The frame rate of the running game, as a plain number in the top left corner of the screen, on a
jailbroken PS5 with system software 13.60. A settings file on the console moves it to another corner
and adds more lines: frame time, lowest, highest and average frame rate, and play time.

SimpleFPS is [Common FPS for PS5](https://github.com/porhe911/Common-FPS-for-PS5) v1.2.1 by porhe911
with a patch. Common FPS stops at system software 10.xx; the patch lets it run on 11.xx to 13.xx,
shows the number alone and adds the settings file. All the real work is theirs.

## Status

Tested on one console only: a PS5 on system software 13.60 with kstuff-lite 1.11 and ShadowMountPlus,
loaded through the ELF loader on port 9021.

- The overlay was seen working there in a PS5 game, as `FPS: 60` in the top left corner.
- The settings file has been used there: the overlay read each change within seconds, and the move to
  the top right corner and the play time line were seen on screen. The spacing of the columns and the
  colours have not been reported on yet.
- In that session the home screen process restarted once while the game kept running, and the overlay
  attached itself again. Two copies of SimpleFPS were running at the time and extra lines were on. The
  cause is not known, so treat anything beyond the default single number as experimental.
- With the default settings the overlay asks the home screen for the same things as the first release:
  one text, updated once a second.
- 11.xx, 12.xx and 13.00 to 13.50 are allowed by the patch but have not been tried by anyone.

Use it at your own risk.

## Use

1. Run your jailbreak as usual, so the ELF loader listens on port 9021.
2. Start a game.
3. Send `simpleFPS.elf` (from the [releases](https://github.com/khalifa007/SimpleFPS/releases)) to the
   console, with any payload sender or with the script here:

   ```
   python send_payload.py simpleFPS.elf <PS5 address>
   ```

The number appears a few seconds later and follows you from game to game. Until the first measurement
it shows `--`.

Coming from the first release, restart the console before sending this one.

Things to know:

- It has to be sent again after every restart of the console.
- Send it while a game is running, not from an autoload list. It waits for a game before it touches the
  home screen.
- `visible=0` in the settings hides it. The overlay itself keeps running until a restart.
- Do not run it together with Common FPS itself or with another FPS overlay.
- Launch it once. Two copies drawing at the same time show as flickering numbers. From this version on
  a second launch should be harmless, because the newer copy takes the overlay over and the older one
  goes quiet, but that has not been tried on a console yet.
- A new build needs a restart of the console first, because the drawing part stays in the home screen.
- It writes a log to `/data/CommonFPS_v1_2_1.log`. Each time it reads the settings, it notes there what
  it understood.

## Settings

The first run writes `/data/simplefps.ini` with the defaults and a comment for every setting. Fetch it
over FTP, change it and put it back. The overlay reads the file once a second, so a saved change shows
while the game runs. A file manager on the console only helps if it reaches the real `/data`: an app
that runs in a sandbox has its own `/data` and does not see the file.

| Setting | Values | Default |
|---|---|---|
| `corner` | `top_left`, `top_right`, `bottom_left`, `bottom_right` | `top_left` |
| `show` | any of `fps`, `frametime`, `min`, `max`, `avg`, `time`, separated by commas, top to bottom | `fps` |
| `labels` | `auto`: names on the extra lines only; `on`: on every line; `off`: none | `auto` |
| `color` | `1` paints the fps number green, yellow or red; `0` keeps it white | `0` |
| `fps_good`, `fps_ok` | green from `fps_good` up, yellow from `fps_ok` up, red below | `55`, `30` |
| `font_size` | `18` to `36` | `24` |
| `margin_x`, `margin_y` | distance from the screen edges | `10`, `10` |
| `visible` | `1` shows the overlay, `0` hides it | `1` |

With `labels=auto` the fps number is always bare, and the other lines get a name when more than one
line is shown. All six lines, `show=fps,frametime,min,max,avg,time`, look like this:

```
60
MS    16.7
MIN     48
MAX     60
AVG     57
TIME  1:23
```

- `frametime` is 1000 divided by the frame rate of the last second, not the time of single frames.
- `min`, `max`, `avg` and `time` start again with each game. A second with no new picture is left out.
- A line the overlay does not understand keeps its default. Deleting the file brings all defaults back.
- The font cannot be measured from outside the home screen, so the columns are placed by estimated
  letter widths. If names and values sit too close or too far apart, that estimate is what to adjust.

## What it does to the console

- It reads the count of pictures the display driver has shown (`/dev/dce`), once a second. It does not
  read or write the game's memory for that.
- It reads `/data/simplefps.ini` once a second, and writes that file when it is not there. It never
  replaces a file that exists.
- It writes its process number to `/system_tmp/simplefps_owner.pid`, so that an older copy can see a
  newer one has started.
- To draw, it loads a small renderer into the home screen process (SceShellUI) and changes one byte
  there: the first byte of `Diagnostics.CheckRunningOnMainThread`, after checking that the bytes are
  the ones it expects, and it reads the byte back afterwards. If anything does not match, it stops and
  changes nothing.

On the test console a first build that could not read that code stopped cleanly, and the game and the
home screen kept running. A fault in this kind of code can still make the home screen restart.

## What the patch changes

`simplefps.patch`, against Common FPS for PS5 at commit `b7969fd`:

- System software 11.xx to 13.xx is accepted. Common FPS refuses anything above 10.xx.
- On those versions the home screen's code is read and patched through the debug interface (MDBG).
  Ptrace I/O, which Common FPS uses from 8.30 to 10.xx, cannot read it on 13.60 (EFAULT).
- The one-byte write tries the plain MDBG write first, then the read-write-execute window Common FPS
  uses on 9.00.
- The number sits in the top left corner instead of the bottom left.
- The `FPS:` label is gone unless asked for, and `--` replaces `Loading`.
- Settings are read from `/data/simplefps.ini`. Common FPS has a settings parser but never opens a file.
- The overlay can show several lines. The controller writes the text and colour of each line into the
  packet it sends to the renderer once a second; the renderer only places and draws them.
- Both programs import exactly the same system functions as in the first SimpleFPS release.

## Build

Linux or WSL with git, cmake and python3, and the
[PS5 payload SDK](https://github.com/ps5-payload-dev/sdk):

```
PS5_PAYLOAD_SDK=/opt/ps5-payload-sdk bash build.sh
```

The script fetches Common FPS and the two sources its build pins (etaHEN and shsrv) at fixed commits,
applies the patch and writes `simpleFPS.elf`. The release file was built this way.

## Credits and license

- [Common FPS for PS5](https://github.com/porhe911/Common-FPS-for-PS5) by porhe911: the overlay itself.
- [etaHEN](https://github.com/etaHEN/etaHEN) by LightningMods and contributors, and
  [shsrv](https://github.com/ps5-payload-dev/shsrv) and the
  [PS5 payload SDK](https://github.com/ps5-payload-dev/sdk) by John Tornblom: sources its build uses.

GPL-3.0-or-later, like Common FPS for PS5. See `LICENSE`.
