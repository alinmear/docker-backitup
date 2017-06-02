#!/bin/bash

remove_quotes() {
    expr="$1"
    expr="${expr%\'}"
    expr="${expr#\'}"
    echo "$expr"
}

[[ $DUPLY_CRON_ENABLED == 'yes' ]] && \
    (crontab -l | grep -E "duply" 2>&1 > /dev/null || ((crontab -l 2>/dev/null; echo "$(remove_quotes "$DUPLY_CRON") duply data backup 2>&1") | crontab -))

[[ $MYSQL_CRON_ENABLED == 'yes' ]] && \
    (crontab -l | grep -E "mysql_backup" 2>&1 > /dev/null || ((crontab -l 2>/dev/null; echo "$(remove_quotes "$MYSQL_CRON") mysql_backup backup 2>&1") | crontab -))
