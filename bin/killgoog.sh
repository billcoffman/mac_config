#!/usr/bin/env bash

#ps axu|grep Google|grep Chrome|cut -c 1-200|awk '{print $2}'|xargs kill
ps axu|grep Google|grep Chrome|cut -c 1-130
