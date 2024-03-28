# What does the script do

The script loads (from a config file) entries for git repositories that supply reShade filters and tries to add them to a merged dirstructure and then to a vkBasalt.conf

The related parameters of all found filters will try to be added to the vkBasalt.conf as well (duplicate filter names could pose problems. see [https://github.com/DadSchoorse/vkBasalt/pull/46#issuecomment-570783537](link))

# how to start
`./run.sh`
