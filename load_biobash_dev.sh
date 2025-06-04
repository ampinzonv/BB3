#!/usr/bin/env/bash

#
# This script sources all the files that make up
# the BioBash utility.
#
# Created by: 
# Andres M. Pinzón [ampinzonv@unal.edu.co]
# Institute for Genetics - National University of Colombia
#

#This variable will be declared here just for development.
BIOBASH_HOME="$(pwd)"
export BIOBASH_HOME

source "${BIOBASH_HOME}/file.sh"
source "${BIOBASH_HOME}/plot_ascii.sh"
source "${BIOBASH_HOME}/blast.sh"
source "${BIOBASH_HOME}/utility.sh"
source "${BIOBASH_HOME}/biobash_core.sh"

