local telescope = require('telescope')

telescope.setup {
  pickers = {
    find_files = {
      hidden = true,
    }
  },
  defaults = {
    mappings = {
      i = {
        ['?'] = require('telescope.actions.layout').toggle_preview
      },
      n = {
        ['?'] = require('telescope.actions.layout').toggle_preview
      }
    },
    preview = {
      hide_on_startup = true
    },
  },
}

telescope.load_extension('projects')
