#!/bin/sh

OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Get options:
show_help() {
  cat << EOF
  Usage: ${0##*/} [-g] [-f flavor] [-B branch] [-t tag] [-n name] [-w port] [-s port] [-a port] [-u port[-port]] [-h]
  Run SDRangel and SDRangelCli in a Docker compose stack.
  -D         use this option to bring down the compose stack (default is to bring up).
             Use the same -g and -c options if any that you used to bring up the stack.
             Other options do not matter.
  -g         Run a GUI variant (server if unset)
  -f flavor  Image flavor. Can be vanilla, nvidia, server16, server24 (default vanilla). Use a flavor relevant to GUI or server variants.
  -B branch  SDRangelCli source branch name (default master)
  -t version Docker SDRangel GUI image tag version (default latest)
  -T version Docker SDRangelCli image tag version (default latest)
  -c name    Docker compose stack name (default compose)
  -r         Number of Rx bits for server version (default 16)
  -n         Container name suffix (default 1)
  -w port    Web client port map to 8080 (default 8080)
  -s port    SSH port map to 22 (default 50022).
  -a port    API port map to 8091 (default 8091).
  -u port(s) UDP port(s) map to same with UDP option (default 9090). You can specify a range as XXXX-YYYY.
  -h         Print this help.
  Examples:
    ./run.sh -g (starts sdrangel/vanilla:latest and sdrangelcli/master:latest)
    ./run.sh -g -f nvidia -t v4.10.4 -c sdrangel -u 9090:9090 (starts sdrangel/nvidia:v4.10.4 and sdrangelcli/master:latest)
    ./run.sh -f server16 -t 38df0a6 -c sdrangel -u 9090:9090 (starts sdrangel/server16:38df0a6 and sdrangelcli/master:latest)
    ./run.sh -f server16 -t v4.10.4 -T v1.1.1 (starts sdrangel/server16:v4.10.1 and sdrangelcli/master:v1.1.1)
EOF
}

sdrangel_flavor="vanilla"
branch_name_cli="master"
image_tag="latest"
image_tag_cli="latest"
name_suffix="1"
stack_name=""
web_port="8080"
ssh_port="50022"
api_port="8091"
udp_port="9090"
run_gui=0
action="up -d"

while getopts "h?Dgf:B:t:T:c:w:s:a:u:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    D)  action="down"
        ;;
    g)  run_gui=1
        ;;
    f)  sdrangel_flavor=${OPTARG}
        ;;
    B)  branch_name_cli=${OPTARG}
        ;;
    t)  image_tag=${OPTARG}
        ;;
    T)  image_tag_cli=${OPTARG}
        ;;
    c)  stack_name="-p ${OPTARG}"
        ;;
    n)  name_suffix=${OPTARG}
        ;;
    w)  web_port=${OPTARG}
        ;;
    s)  ssh_port=${OPTARG}
        ;;
    a)  api_port=${OPTARG}
        ;;
    u)  udp_port=${OPTARG}
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift
# End of get options

if [ -x "$(command -v nmcli)" ]; then
    export DNS=$(nmcli dev show | grep 'IP4.DNS' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1)
else
    export DNS=$(grep nameserver /etc/resolv.conf | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1)
fi
export USER_UID=$(id -u)
export SDRANGEL_FLAVOR=${sdrangel_flavor}
export BRANCH_NAME_CLI=${branch_name_cli}
export IMAGE_VERSION=${image_tag}
export IMAGE_VERSION_CLI=${image_tag_cli}
export NAME_SUFFIX=${name_suffix}
export WEB_PORT=${web_port}
export SSH_PORT=${ssh_port}
export API_PORT=${api_port}
export UDP_PORT=${udp_port}

if [ "$run_gui" -eq 1 ]; then
    docker-compose -f compose_gui.yml ${stack_name} ${action}
else
    docker-compose -f compose_server.yml ${stack_name} ${action}
fi
