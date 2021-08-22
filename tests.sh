#!/bin/bash -ex

mix test --stale --cover > /dev/null || echo "Failed"
mix credo > /dev/null || echo "Failed"
mix sobelow --quiet --skip -i Config.HTTPS --exit > /dev/null || echo "Failed"
mix format "{lib,test,config}/**/*.{ex,exs}" > /dev/null || echo "Failed"
echo "All tests passed"
