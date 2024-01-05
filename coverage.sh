forge coverage --report lcov \
&& lcov --rc lcov_branch_coverage=1 \
    --output-file forge-pruned-lcov.info \
    --remove lcov.info "test/" && \
genhtml lcov.info -o coverage-report --branch-coverage