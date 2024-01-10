forge coverage --report lcov \
&& lcov --rc lcov_branch_coverage=1 \
    --output-file forge-pruned-lcov.info \
    --remove lcov.info "test/" "script/" && \
genhtml forge-pruned-lcov.info -o coverage-report --branch-coverage