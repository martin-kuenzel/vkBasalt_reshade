#!/usr/bin/env bash
IFS=$'\n';

PATH_SCRIPT=$(realpath $(dirname ${BASH_SOURCE[0]}));
FILE_DEFAULT_VKBASALT=${PATH_SCRIPT}/vkBasalt.conf.default

PATH_BUILD=${PATH_SCRIPT}/build
PATH_SHADERS=${PATH_BUILD}/shaders

FILE_VKBASALT=${PATH_BUILD}/vkBasalt.conf

echo "cleaning build path" && rm "${PATH_BUILD}/*" -rf;

repos_shaders=("https://github.com/CeeJayDK/SweetFX sweetfx-shaders" "https://github.com/martymcmodding/qUINT martymc-shaders" "https://github.com/BlueSkyDefender/AstrayFX astrayfx-shaders" "https://github.com/prod80/prod80-ReShade-Repository prod80-shaders" "https://github.com/crosire/reshade-shaders reshade-shaders_slim"); 

fn_exit_err() { echo "$2"; exit $1; }
fn_exit() { echo exiting...; echo done; }
trap fn_exit EXIT;

command -v git >/dev/null || fn_exit_err $? "could not find git";

fn_git_load_shaders() { 
	mkdir -p ${PATH_SHADERS} || fn_exit_err $? "could not create shaders basedir";
	cd ${PATH_SHADERS} || fn_exit_err $? "could not open shaders basedir";
	for i in ${repos_shaders[@]}; do 
		git clone $(printf $i|awk '{print $1}'); 
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
};

fn_create_conf_vkbasalt() {
	(
		[ -e ${FILE_DEFAULT_VKBASALT} ] && cat ${FILE_DEFAULT_VKBASALT};
		echo 

		## try to generate filters with options from reShade fx files for vkBasalt.conf (https://github.com/DadSchoorse/vkBasalt/pull/46)
		# duplicate parameters will (have to) be removed
		for i in ${PATH_SHADERS}/Merged/Shaders/*.fx; do
			echo -e "\n#$(basename $i)\n";
			echo -e "$(basename ${i} | sed 's/\.[^.]*$//') = $PATH_SCRIPT/shaders/Merged/Shaders/$(basename $i)\n";

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
