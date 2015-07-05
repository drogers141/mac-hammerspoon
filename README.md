# Mac-hammerspoon

## Mac Desktop Utility Layer
This work is part of my ongoing effort to enable powerful customization and window manipulation for OS X for my needs.
Some goals:

- arbitrary window movement and resizing with keybindings
- awareness of state of windows in differing contexts
  - state of windows on a particular desktop, i.e. Space in Mac-speak
  - awareness of different screens in combination with desktop state
      - i.e. - number-of-contexts = number-of-screens * number-of-desktops
- create a functionality layer with above that allows arbitrary scripting as needed

## Uses Hammerspoon
- https://github.com/Hammerspoon/hammerspoon
  - very useful stuff there and responsive group
- ported from Hydra (previous implementation of project that Hammerspoon forked)


## Spaces
- Spaces support is ridiculous in Mac at this point
- This work depends on internal apis that are deprecated
  - implemented in asmagill's port from sdegutis mjolnir/hydra work
    - https://github.com/asmagill/hammerspoon_asm.undocumented
  - unsure if they are compatible with Yosemite
  - only need an indicator of which desktop (space) is current
    - so possible to find future internal apis if Apple doesn't make it public
- If this were not the case I would probably push to disseminate as the functionality is damned handy

