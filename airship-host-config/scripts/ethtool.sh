#!/bin/bash
set -e
echo script name: ${BASH_SOURCE[0]}
eth=`which ethtool`
echo command: $eth $@
$eth $@
