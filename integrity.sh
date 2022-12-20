#!/bin/sh
# CopyRight Xunillen 2022
# Based on CALOMEL IDS script.

KEY=
DIR=/hash_dir
KWORDS=cksum,md5digest,sha1digest,sha256digest

# Put 0600 premission on this script

# Files that always change because of relinking:
#
# lib/libc.so.96.2: 
# lib/libcrypto.so.50.0: 
# libexec: 
# libexec/ld.so: 
# libexec/ld.so.save: 
# share/relink: 
# share/relink/kernel/GENERIC.MP: 
# share/relink/kernel/GENERIC.MP/bsd: 
# share/relink/kernel/GENERIC.MP/gap.link: 
# share/relink/kernel/GENERIC.MP/gap.o: 
# share/relink/kernel/GENERIC.MP/lorder: 
# share/relink/kernel/GENERIC.MP/newbsd.gdb: 
# share/relink/kernel/GENERIC.MP/relink.log: 

help() {
	echo "\n Simple script to check integrity of the host OpenBSD system.\n"
	echo "Command usage: \n./integrity gen <path to directory>"
	echo "./integrity ver <path to directory>"
	echo "./integrity install <path to directory> - broken. Put integrity.sh in / if you want to use this"
	echo "\n<path to directory> - Location to directory where hash files are stored."
	echo "If directory does not exist, it will be created. While using gen arg, existing hash files"\
		"will be moved to old_hash folder."
	echo "\nNOTE: This tool is designed to be used from bsd.rd, as hash files can be modified"\
		"if host system is compromised. If you need to verify host system without booting bsd.rd"\
		"from second storage media, then the best way is to store hash files to usb and verify host system"\
		"while not connected to internet. This is not good way to verify integrity, but is good enough in some"\
		"cases"
}

install() {
        DIR=$2
        if [[ -d $DIR ]]; then
		cd $DIR
		if [[ (! -e "hash_bin") || (! -e "hash_sbin") || (! -e "hash_usr")]] then
        		echo "Hash files not found. Make sure you completed at least one hash generation with gen arg"\
                		"with the same directory parameter you provided here"\
                		"\n(aka. please run \"./integrity gen $DIR\")"
			exit
		fi
	else
		echo "Given folder not found... exiting"
		exit
	fi
        echo "Adding script to local.rc..."
	echo "$1 ver $2" >> /etc/rc.local
        echo "Done!"
}

if [[ $1 = "help" || $# -eq 0 ]]; then
	help
	exit
fi

if [[ $1 = "install" ]]; then
        if [[ -z "$2" ]]; then
                echo "Second argument not supplied. ./integrity install <path to directory>"
                exit
        fi
	install "$0" "$2"
	exit
fi

if [[ $1 = "gen" ]]; then
	if [[ -z "$2" ]]; then
		echo "Second argument not supplied. ./integrity gen <path to directory>"
		exit
	fi
	DIR=$2	# Note: Make default path
	if [ -d $DIR ]; then
		# Remove current hash values
		#echo "Removing:"
		#rm -rvf $DIR
		#mkdir $DIR
		# Move old hash files to old_hash folder
		cd $DIR
		echo "Moving old hash files..."
		if [[ ! -d old_hash ]]; then
			mkdir old_hash
		fi
		mv hash_* old_hash/
	else
		echo "Creating directory..."
		mkdir $DIR
	fi
	# enter dir
	cd $DIR

	# Generate new hash values
	logger -t "[Integrity]" "Generating new integrity hash files... Hash files location: $DIR. hash functions: $KWORDS"
	echo "Generating bsd.rd hash file"
	sha256 /bsd.rd > hash_bsdrd
	echo "Generating bsd.sp hash file"
	sha256 /bsd.sp > hash_bsdsp
	echo "Generating /bin hash file"
	mtree -c -K $KWORDS -s $KEY -p /bin > hash_bin
        echo "Generating /sbin hash file"
	mtree -c -K $KWORDS -s $KEY -p /sbin > hash_sbin
	echo "Generating /etc hash file"
	mtree -c -K $KWORDS -s $KEY -p /etc > hash_etc
        echo "Generating /usr hash file"
        mtree -c -K $KWORDS -s $KEY -p /usr > hash_usr
	# Set premissions
	chmod 600 $DIR/hash_*
        logger -t "[Integrity]" "Generating new integrity hash files completed!"
	exit
fi

if [[ $1 = "ver" ]]; then
        if [[ -z "$2" ]]; then
                echo "Second argument not supplied. ./integrity ver <path to directory>"
                exit
        fi
        DIR=$2
	cd $DIR

	# Check if out.res exists and delete it if it does
	if [[ -f out.res ]]; then
		rm out.res
	fi

        logger -t "[Integrity]" "Verifying integrity hash files... Hash files location: $DIR. hash functions: $KWORDS"
	echo "Verifying bsd.rd..."
	sha256 -c hash_bsdrd
	echo "Verifying bsd.sp..."
	sha256 -c hash_bsdsp
	echo "Verifying /bin..."
	mtree -s $KEY -p /bin < hash_bin >> out.res 2>&1
	echo "Verifying /sbin..."
	mtree -s $KEY -p /sbin < hash_sbin >> out.res 2>&1
        echo "Verifying /etc..."
        mtree -s $KEY -p /etc < hash_etc >> out.res 2>&1
	echo "Verifying /usr..."
	mtree  -s $KEY -p /usr < hash_usr >> out.res 2>&1
	echo "System verification completed! System and verification results can be viewed in mail."
        logger -t "[Integrity]" "System Verification completed!"
	cat out.res | mail -s "Host system integrity check" root
	exit
fi
