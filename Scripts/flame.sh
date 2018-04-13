#!/bin/bash

# Flame everything in this directory, copy search_setup.xml from upstream then setup

rm -rf *
cp ../search_setup.xml .
$setup
