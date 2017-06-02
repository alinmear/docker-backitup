#!/bin/bash

[ ! -d /backup/duply_export ] && mkdir -p /backup/duply_export
cp -rv /root/.duply/* /duply_export
