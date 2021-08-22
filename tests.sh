#!/bin/bash -ex

mix test --stale --cover > /dev/null
mix credo > /dev/null
mix sobelow --quiet --skip -i Config.HTTPS --exit > /dev/null
mix format "{lib,test,config}/**/*.{ex,exs}" > /dev/null
echo "All tests passed"
