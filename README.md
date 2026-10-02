# SimpleFPS
<img width="510" height="680" alt="image" src="https://github.com/user-attachments/assets/1f62bce6-df23-4b37-8c7f-b669290ebb9f" />

The frame rate of the running game, as a plain number in the top left corner of the screen, on a
jailbroken PS5 with system software 13.60.

SimpleFPS is [Common FPS for PS5](https://github.com/porhe911/Common-FPS-for-PS5) v1.2.1 by porhe911
with a small patch. Common FPS stops at system software 10.xx; the patch lets it run on 11.xx to 13.xx
and shows the number alone. All the real work is theirs.

## Status

Tested on one console only: a PS5 on system software 13.60 with kstuff-lite 1.11 and ShadowMountPlus,
loaded through the ELF loader on port 9021.

- The overlay was seen working there in a PS5 game, as `FPS: 60` in the top left corner.
- This release changes the text to the number alone. That last change has not been checked on screen yet.
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

Things to know:

- It has to be sent again after every restart of the console.
- Send it while a game is running, not from an autoload list. It waits for a game before it touches the
  home screen.
- There is no off switch. The number leaves the screen with a restart.
- Do not run it together with Common FPS itself or with another FPS overlay.
- It writes a log to `/data/CommonFPS_v1_2_1.log`.

## What it does to the console

- It reads the count of pictures the display driver has shown (`/dev/dce`), once a second. It does not
  read or write the game's memory for that.
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
- The `FPS:` label is left empty, and `--` replaces `Loading`.

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
