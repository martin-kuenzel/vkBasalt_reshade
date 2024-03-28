# What does the script do

The script loads (from a config file sources_reshade.conf) entries for git repositories that supply reShade filters and tries to add them to a merged dirstructure and then to a vkBasalt.conf

The related parameters of all found filters are tried to be added to the vkBasalt.conf as well (duplicate filter names could pose problems. see [https://github.com/DadSchoorse/vkBasalt/pull/46#issuecomment-570783537](link))

the vkBasalt.conf will contain a prefilled head part that can be defined in vkBasalt.conf.default.head

# how to start
`./run.sh`
