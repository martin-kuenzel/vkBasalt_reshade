#!/usr/bin/env bash
IFS=$'\n';

PATH_SCRIPT="$(realpath $(dirname ${BASH_SOURCE[0]}))";
FILE_DEFAULT_VKBASALT="${PATH_SCRIPT}/vkBasalt.conf.default.head"

PATH_BUILD="${PATH_SCRIPT}/build"
PATH_SHADERS="${PATH_BUILD}/shaders"

FILE_VKBASALT="${PATH_BUILD}/vkBasalt.conf"

fn_exit_err() { echo "$2"; exit $1; }
fn_exit() { echo exiting...; echo done; }
trap fn_exit EXIT;

command -v git >/dev/null || fn_exit_err $? "could not find git";

echo "cleaning build path";
find ${PATH_BUILD} -mindepth 1 -maxdepth 1 -type d -execdir rm -rf {} \; ;
rm ${FILE_VKBASALT};

fn_git_load_shaders() { 
	mkdir -p ${PATH_SHADERS} || fn_exit_err $? "could not create shaders basedir";
	cd ${PATH_SHADERS} || fn_exit_err $? "could not open shaders basedir";
	for i in $(grep -E '^http.*' ${PATH_SCRIPT}/sources_reshade.conf|sed 's/\s//g'); do
		git clone ${i} #|| exit_err $? "Error while trying to fetch shaders from ${i}";
	done;
}

fn_link_shaders() {
	cd ${PATH_SHADERS} || fn_exit_err $? "could not open shaders basedir @${PATH_SHADERS}";
	mkdir -p Merged/{Textures,Shaders} || fn_exit_err $? "could not create dirstructure for merged shaders";
	cd Merged/Textures;
	find ../.. -wholename '*/*extures/*.*' -type f -exec ln -fs {} ./ \; ;
	cd -;
	cd Merged/Shaders;
	find ../.. -wholename '*/*haders/*.fx*' -type f -exec ln -fs {} ./ \; ;
	cd -;
}

fn_create_conf_vkbasalt() {
	(
		[ -e ${FILE_DEFAULT_VKBASALT} ] && cat ${FILE_DEFAULT_VKBASALT};
		echo 

		## try to generate filters with options from reShade fx files for vkBasalt.conf (https://github.com/DadSchoorse/vkBasalt/pull/46)
		# duplicate parameters will (have to) be removed
		for i in ${PATH_SHADERS}/Merged/Shaders/*.fx; do
			echo -e "\n#$(basename $i)\n";
			echo -e "$(basename ${i} | sed 's/\.[^.]*$//') = ${PATH_SHADERS}/Merged/Shaders/$(basename $i)\n";

			echo $(grep -E "(uniform\s*(float|bool|int)|^>)" ${i}) | sed 's/\s*;\s*/\n/g' | \
		        awk '$NF ~/^[0-9]+(\.[0-9])*|true|false$/ {print $3" = "$NF}' | \
		        awk '$1 !~/^[0-9]+(\.[0-9])*|true|false$/ {print $0}' | \
			sed 's/)$//g' | \
			awk '!x[$0]++' # https://linuxsecurity.expert/how-to/remove-duplicates-from-file-without-sorting/
		done 
		echo

		echo "reshadeTexturePath = ${PATH_SHADERS}/Merged/Textures";
		echo "reshadeIncludePath = ${PATH_SHADERS}/Merged/Shaders";
	) > ${FILE_VKBASALT}
}

fn_git_load_shaders;
fn_link_shaders;
fn_create_conf_vkbasalt;
