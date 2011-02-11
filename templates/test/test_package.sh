#! /bin/sh
############################################################################

usage="usage: %s [-h] PROJECT_DIR\n"
option="       %s   %s\n"
while getopts "h" opt
do
  case $opt in
  h)  printf "$usage" $0
      printf "$option" "-h" "prints this help"
      exit 0;;
  ?)  printf "$usage" $0
      exit 2;;
  esac
done
shift $(($OPTIND - 1))

assert_status_equal () {
  expected=$1; actual=$2; lineno=$3
  
  if [ $actual -ne $expected ]
  then 
    echo "[$0:$lineno] exit status $actual (expected $expected)"
    exit 1
  fi
}

################################### test ###################################
project_dir=$1

if [ ! -d "$project_dir" ]
then
  echo "not a project directory: $project_dir"
  exit 1
else
  # expand project_dir
  cd -- "$project_dir" > /dev/null
  project_dir=$(pwd)
  cd - > /dev/null
fi

project_name=${PROJECT_NAME:-$(basename -- "$project_dir" | sed 's/^test_//')}
project_test_name=${PROJECT_TEST_NAME:-"$project_name"_test}

ssh_config_file=${SSH_CONFIG_FILE:-config/ssh}
remote_test_dir=${REMOTE_TEST_DIR:-vm/test}

#
# build packages
#

# build
packages="$(bundle exec linecook build --force)"

for package_dir in $packages
do
host=$(basename -- "$package_dir")

# transfer
ssh -q -T -F "$ssh_config_file" "$host" -- <<SETUP
rm -rf "$remote_test_dir"
if [ "$(dirname $remote_test_dir)" != "" ]
then mkdir -p "$(dirname $remote_test_dir)"
fi
SETUP

scp -q -r -F "$ssh_config_file" "$package_dir" "$host:$remote_test_dir"
assert_status_equal 0 $? $LINENO

# run
ssh -q -T -F "$ssh_config_file" "$host" -- <<RUN
cd "$remote_test_dir"
chmod +x "$project_name"
sudo ./"$project_name"
RUN
assert_status_equal 0 $? $LINENO
done

#
# test packages
#

for package_dir in $packages
do
host=$(basename -- "$package_dir")

# check
ssh -q -T -F "$ssh_config_file" "$host" -- <<CHECK
cd "$remote_test_dir"
if [ -f "$project_test_name" ]
then
  chmod +x "$project_test_name"
  ./"$project_test_name"
fi
CHECK
assert_status_equal 0 $? $LINENO
done
################################## (test) ##################################
