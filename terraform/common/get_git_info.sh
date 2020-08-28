#!/bin/bash
set -e

BRANCH=$(git status | head -n1)
HEAD_HASH=$(git rev-parse HEAD | awk '{print $1}')
REF=$(git show-ref | grep $HEAD_HASH  |  awk '{print $2}'| tr "\n" ",")
TAG=$(git describe --tags) 

echo "{\"branch\": \"${BRANCH}\", \"hash\": \"${HEAD_HASH}\", \"reference\": \"${REF}\", \"tag\": \"${TAG}\"}"
