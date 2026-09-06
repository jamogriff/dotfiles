require('dashboard').setup({
  theme = 'doom',
  config = {
    header = {
      '',
      '',
      '+------------------------------------------------+',
      '|     *  .   *                   o *             |',
      '|                                                |',
      '|    .--.      .--.    .--.                      |',
      '|                                                |',
      '|                      /‾‾                       |',
      '|                     /    ‾     /‾‾             |',
      '|        /‾‾         /      ‾   /    ‾    /‾‾    |',
      '|       /    ‾  /‾‾ /        ‾ /      ‾ /    ‾   |',
      '|______/______‾/    ‾________________/______‾____|',
      '|                                                |',
      '|  ~ ~  ~     ~  ~~  ~   ~  ~~ ~    ChatGPT 2025 |',
      '+------------------------------------------------+',
      '',
    },
    center = {
      {
        icon = '   ',
        desc = 'Find File              ',
        key = 'f',
        action = 'Telescope find_files'
      },
      {
        icon = '   ',
        desc = 'Recent Files',
        key = "h",
        action = 'Telescope oldfiles'
      },
      {
        icon = '   ',
        desc = 'Find Word',
        key = 'g',
        action = 'Telescope live_grep'
      },
    },
    footer = {"Silence is golden."},
    vertical_center = false,
  }
})
