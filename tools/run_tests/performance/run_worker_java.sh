#!/bin/bash
# Copyright 2015 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

# Enter repo root
cd "$(dirname "$0")/../../.."

# Enter the grpc-java repo root (expected to be next to grpc repo root)
cd ../grpc-java

#benchmarks/build/install/grpc-benchmarks/bin/benchmark_worker "$@"

last_arg=${@: -1}
core=${@:$#-1:1}
total_cpu=`grep -c ^processor /proc/cpuinfo`
phys_cpu=$(( $total_cpu / 2 ))
numa0_0=$(( $total_cpu / 4 - 1))
numa1_0=$(( $total_cpu * 2 / 4 - 1))
numa0_1=$(( $total_cpu * 3 / 4 - 1))
numa1_1=$(( $total_cpu - 1))

if [ $core -gt $phys_cpu ]; then
	echo "cross numa not supportted "
	exit
fi

if [ "$last_arg" -eq 0 ]; then
  echo "Last argument is 0. Performing Action 1."
  set -- "${@:1:$(($#-2))}"
  echo "all arguments = $@"
  #numactl -N $last_arg -m $last_arg benchmarks/build/install/grpc-benchmarks/bin/benchmark_worker "$@"
  # Perform Action 1 here
  if [ $core -gt $(( $numa0_0 + 1 )) ]; then
  	cpu0=$numa0_0
	echo $core
	cpu1=$(($numa1_0 + ($core - $numa0_0) -1 ))
	numactl -C 0-$cpu0,$(($numa1_0 + 1))-$cpu1 benchmarks/build/install/grpc-benchmarks/bin/benchmark_worker "$@"
  else
	numactl -C 0-$(($core-1)) benchmarks/build/install/grpc-benchmarks/bin/benchmark_worker "$@"
  fi
elif [ "$last_arg" -eq 1 ]; then
  echo "Last argument is 1. Performing Action 2."
  # Perform Action 2 here
  set -- "${@:1:$(($#-2))}"
  echo "all arguments = $@"
  #numactl -N $last_arg -m $last_arg benchmarks/build/install/grpc-benchmarks/bin/benchmark_worker "$@"
  #numactl -C 28-55 benchmarks/build/install/grpc-benchmarks/bin/benchmark_worker "$@"
  if [ $core -gt $(( $numa0_0 + 1 )) ]; then
  	cpu0=$numa1_0
	cpu1=$(($numa0_1 + ($core - $numa0_0) -1 ))
	numactl -C $(( $numa0_0 + 1 ))-$cpu0,$(($numa0_1 + 1))-$cpu1 benchmarks/build/install/grpc-benchmarks/bin/benchmark_worker "$@"
  else
	  numactl -C $(($numa0_0+1))-$(($numa0_0+$core)) benchmarks/build/install/grpc-benchmarks/bin/benchmark_worker "$@"
  fi
else
  echo "Invalid last argument. Expected 0 or 1."
  echo "all arguments = $@"
  benchmarks/build/install/grpc-benchmarks/bin/benchmark_worker "$@"
fi
#set -- "${@:1:$(($#-2))}"
#benchmarks/build/install/grpc-benchmarks/bin/benchmark_worker "$@"
