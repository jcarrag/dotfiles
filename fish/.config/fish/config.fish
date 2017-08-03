# install fundle if not present
if not functions -q fundle; eval (curl -sfL https://git.io/fundle-install); end

# plugins
fundle plugin 'tuvistavie/fish-fastdir'
fundle plugin 'fisherman/git_util'
fundle plugin 'fisherman/humanize_duration'
fundle plugin 'fisherman/last_job_id'
fundle plugin 'fisherman/fzf'
fundle plugin 'fisherman/simple'
fundle init
