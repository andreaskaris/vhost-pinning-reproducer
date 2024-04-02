#!/bin/bash

MEMORY=16384
PCIDEVICES=$(echo "-a" "${PCIDEVICE_OPENSHIFT_IO_VHOSTNET}" | sed 's/\,/ -a/g')
NUM_PCIDEVICES=$(echo "${PCIDEVICE_OPENSHIFT_IO_VHOSTNET}" | sed 's/,/\n/g' | wc -l)
TWICE_NUM_PCIDEVICES=$((NUM_PCIDEVICES * 2))

CPUS=$(awk '/Cpus_allowed_list/ {print $NF}' < /proc/self/status | sed 's/,/ /g')
CPU_LIST=""
i=0
for cpu in $(echo -n "$CPUS " | tac -s ' '); do
    # We're actually getting one more CPU than TWICE_NUM_PCIDEVICES on purpose.
    if [ ${i} -gt ${TWICE_NUM_PCIDEVICES} ]; then
        break
    fi
    i=$((i+1))
    CPU_LIST="${CPU_LIST},${cpu}"
done
CPU_LIST=$(echo "${CPU_LIST}" | sed 's/^,//')
FIRST_CPU=$(echo "$CPUS" | awk '{print $1}')

VDEVS=""
for i in $(seq 0 "$((NUM_PCIDEVICES - 1))"); do
    VDEVS="${VDEVS} --vdev=virtio_user${i},path=/dev/vhost-net,queue_size=1024,iface=vf${i} "
done

PORTLIST=""
for i in $(seq 0 "$((NUM_PCIDEVICES - 1))"); do
    PORTLIST="${PORTLIST},${i},$((NUM_PCIDEVICES + i))"
done
PORTLIST=$(echo "${PORTLIST}" | sed 's/^,//')

cat <<EOF > /tmp/commands.txt
set portlist ${PORTLIST}
show config fwd
show port info all
show port stats all
start
EOF

COMMAND="taskset -c ${FIRST_CPU} /usr/bin/dpdk-testpmd -l ${CPU_LIST} -m${MEMORY} --file-prefix=0 ${PCIDEVICES} ${VDEVS} -- -i --nb-cores=${TWICE_NUM_PCIDEVICES} --cmdline-file=/tmp/commands.txt --portmask=f --rxq=1 --txq=1 --forward-mode=io"

echo "Running testpmd, showing statistics every 10 seconds:"
echo "${COMMAND}"
( while true ; do echo 'show port stats all' ; sleep 10 ; done ) | \
${COMMAND}

echo "FAILURE! If we got here, this means that it's time for troubleshooting. Testpmd did not run or crashed!"
sleep infinity
