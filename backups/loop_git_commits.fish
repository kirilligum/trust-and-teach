#!/usr/bin/env fish
# set -x
set fish_trace 1
# set commits_to_test \
# 557a5b960454baa9e6662e79476391b861b7d5c1 \
# ef36f5a3cc3486d4edefbab094434425b6d85ead \
# 99a36b8dc335e27d5223a30d2b00a66fc31ebb2a \
# e8fcf8eefc67dc0484687aa1cb3471dbf41b32e6 \
# 774354cee3c60a2d507fa264aac24fb6284c85fd \
# 3a9034fa879ac1f0d6bc8238843c246083c2bdf2 \
# 740eceb2fd0dd6342adba9e7ee2d3f1bfb74d7de \
# a49bbd12b88a1733c9d17ee3edf66ff14fbd699e \
# 2d9d0c27c2ad6fbbd075c0eadba654a5890bfa39 \
# f93d0316ce330964869063691d3a7afaafbe7aa2 \
# 7fb5bfb22ed11adea3dd1283f8e1b4884dc08389 \
# c539ca1a432b476a4a6851c0960d846c5f156807 \
# 184a437dbcb156bb8de5e5447435f25a7e748fd8 \
# 0b916935672e716a76eca9fcdf8fd778561b5e1e \
# 087b7e12c25c14bf77efeacd76c756029bc6aa79 \
# b978fdcf3c703e615176f22885beb13f7b87c49e \
# 6169f7ad084d8c09bbc0ef21bedb7f40ca2d78aa \
# 8bec81b3c8f341951986871f9219bb6d64020237 \
# 5f9f391ce85cc989b391c9bef7bffbb22cd81dd7 \

set commits_to_test \
ef36f5a3cc3486d4edefbab094434425b6d85ead \

set debug_date (date -uIs)
set log_path_date (pwd)"/runs_history/$debug_date/"



# source coin_toss_vars.fish
source test_cartesi_voucher.fish

for c in $commits_to_test
  set log_path_date_commit $log_path_date"$c/"
  mkdir -p $log_path_date_commit
  set log_filename $log_path_date_commit"commit.log"
  echo "testing commit ------------: $c" 
  echo "testing commit: $c" &| tee -a $log_filename
  git checkout $c &| tee -a $log_filename
  git diff --name-status HEAD^ -- ':!* .md' &| tee -a $log_filename
  test_cartesi_voucher -p $log_path_date_commit &| tee -a $log_filename
end

