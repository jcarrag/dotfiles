local telescope = require('telescope')

telescope.setup {
  defaults = {
    mappings = {
      i = {
        ['?'] = require('telescope.actions.layout').toggle_preview
      }
    },
    preview = {
      hide_on_startup = true
    }
  }
}

telescope.load_extension('projects')
