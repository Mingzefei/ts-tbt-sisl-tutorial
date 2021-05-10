#!/bin/bash

url=www.student.dtu.dk/~nicpa/sisl/workshop/21
indir=$HOME/TBT-TS-sisl-workshop


if command -v wget &> /dev/null ; then
    function download_file {
	local url=$1
	local out=$2
	shift 2
	wget -O $out $url
	[ $? -ne 0 ] && echo "Failed to download: $url" && exit 1
    }
elif command -v curl &> /dev/null ; then
    function download_file {
	local url=$1
	local out=$2
	shift 2
	curl -o $out -LO $url
	[ $? -ne 0 ] && echo "Failed to download: $url" && exit 1
    }
else
    echo "Cannot find either wget or curl command, please install one of them on your machine"
    exit 1
fi

function _help {
    echo "This script may be used to install the dependencies for the"
    echo "tutorial such as Python, numpy, scipy matplotlib, jupyter, sisl and z2pack."
    echo ""
    echo "This script is a two-step script. Please read below."
    echo ""
    echo "Running this script in installation mode will download and install conda"
    echo "conda provides both Siesta executables as well as the sisl and dependency packages"
    echo "so once installed all required infrastructure is available."
    echo "It does, however, require a disk space of approximately >4GB"
    echo ""
    echo "To use the conda framework, run this script in installation mode:"
    echo ""
    echo "  $0 install"
    echo ""
    echo "If you can install Siesta 4.1.5 and sisl 0.11.0 and the rest of the dependencies"
    echo "manually then you won't be needing the above installation procedure."
    echo "However, we cannot assist installing the packages manually."
    echo ""
    echo "Once the above step is fulfilled you should run the download part"
    echo "of the script. It will download the required files for the tutorial:"
    echo ""
    echo "  $0 download"
    echo ""
}

if [ $# -eq 0 ]; then
    _help
    exit 1
fi

# First we get the current directory
cwd=$(pwd)

# Figure out if we are dealing with UNIX or MacOS
os=linux
case "x$OSTYPE" in
    xlinux*)
	os=linux
	;;
    xdarwin*)
	os=macos
	;;
    x*)
	# Try and determine using uname
	case "$(uname -s)" in
	    Linux*)
		os=linux
		;;
	    Darwin*)
		os=macos
		;;
	    *)
		echo "Are you using MingGW or FreeBSD? Or a ($(uname -s))?"
		echo "Either way this installation script does not work for your distribution..."
		exit 1
		;;
	esac
	;;
esac

action=install
case $1 in
    install)
	# do nothing, we use the OS to determine stuff
	action=install
	;;
    update)
	# Update this script
	# Try and update
	base=$(basename $0)
	cp $cwd/$0 $cwd/old_$base
	download_file $url/install_tutorial.sh $cwd/new_$base
	if [ $? -eq 0 ]; then
	    mv $cwd/new_$base $cwd/$base
	    chmod u+x $cwd/$base
	    echo ""
	    echo "Successfully updated script..."
	    rm $cwd/old_$base
 	fi
	exit 0
	;;
    download)
	action=download
	;;
    *)
	echo "###########################################"
	echo "# Unknown argument: $1"
	echo "#"
	echo "# Should be either 'install', 'update' or 'download'"
	echo "#"
	echo "###########################################"
	echo ""
	_help
	exit 1
	;;
esac


function conda_install {
    local exe=$1 ; shift

    [ ! -e $exe ] && download_file https://repo.anaconda.com/miniconda/$exe $exe

    if [ -e $indir/miniconda3/etc/profile.d/conda.sh ]; then
	# it should already be installed
	source $indir/miniconda3/etc/profile.d/conda.sh
    else
	sh ./$exe -b -s -f -p $indir/miniconda3
	source $indir/miniconda3/etc/profile.d/conda.sh
    fi

    conda install -c conda-forge -y siesta=4.1.5 sisl=0.11.0 matplotlib jupyter pyamg

    # The inelastica package requires also the compilers and static libraries
    conda install -c conda-forge -y c-compiler fortran-compiler libblas liblapack

    # remove unused tarballs (no need for them to be around)
    conda clean -t -y

    echo ""
    echo "Before you can run exercises etc. you should execute the following:"
    echo ""
    echo " source $indir/setup.sh"
    echo ""
    {
	echo "#!/bin/bash"
	echo "source $indir/miniconda3/etc/profile.d/conda.sh"
	echo "conda activate"
    } > $indir/setup.sh

    source $indir/setup.sh

    # now install the different packages

    # z2pack
    pip install z2pack

    # inelastica
    git clone https://github.com/tfrederiksen/inelastica.git
    cd inelastica
    python setup.py install
    [ $? -ne 0 ] && exit 1
    cd ../
    rm -rf inelastica

    # hubbard
    git clone https://github.com/dipc-cc/hubbard.git
    cd hubbard
    python setup.py install
    [ $? -ne 0 ] && exit 1
    cd ../
    rm -rf hubbard
}

# Function for installation on Linux
function linux_install {
    conda_install Miniconda3-latest-Linux-x86_64.sh
}


function macos_install {
    conda_install Miniconda3-latest-MacOSX-x86_64.sh
}

function install_warning {
    echo "RUNNING THIS SCRIPT IS AT YOUR OWN RISK!!!"
    echo "THIS SCRIPT IS MADE FOR HELPFUL PURPOSE, BUT YOU ARE"
    echo "RESPONSIBLE FOR ANY ERRORS/DATALOSSES THIS SCRIPT MAY INFER."
    echo "IF YOU DO NOT WANT TO RUN THIS SCRIPT PRESS:"
    echo ""
    echo "  CTRL+^C"
    echo ""
    echo "Please ensure you have more than 5 GB of disk space available!"
    echo ""
    sleep 3
}

# Now create a common folder in the top-home directory

function download_warning {
    echo ""
    echo "This script will create a folder in your $HOME directory:"
    echo "  $HOME/TBT-TS-sisl-workshop"
    echo "where all the tutorials and executable files will be downloaded."
    echo ""
}

function install_test_sisl {
    echo ""
    echo " Will try and run sisl"
    echo "    import sisl ; print(sisl.__version__, sisl.__file__)"
    python -c "import sisl ; print(sisl.__version__, sisl.__file__)"
    if [ $? -ne 0 ]; then
	echo "Failed running sisl, please mail the organizer with the error message (unless some of the installations failed)"
    fi
}

# create installation directory
mkdir -p $indir
pushd $indir

if [ $action == install ]; then
    # os will be download
    download_warning
    install_warning
    case $os in
	linux)
	    linux_install
	    ;;
	macos)
	    macos_install
	    ;;
    esac
    install_test_sisl

    exit 0
else
    download_warning
fi


# Download latest tutorial files
if [ -e sisl-TBT-TS.tar.gz ]; then
    rm sisl-TBT-TS.tar.gz
fi
download_file $url/sisl-TBT-TS.tar.gz sisl-TBT-TS.tar.gz

echo ""
echo "In folder"
echo "   $indir"
echo "you will find everything needed for the tutorial."
echo "If you are using the conda installation provided by this script"
echo "please always start your sessions by executing:"
echo ""
echo "  source $indir/setup.sh"
echo ""
echo "which will correctly setup the environment for you."
echo "Run (after you have restarted your shell):"
echo "  which tbtrans"
echo "and check it returns $indir/miniconda3/bin/tbtrans"
