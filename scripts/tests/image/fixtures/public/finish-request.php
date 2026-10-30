<?php
echo "finish-request-ok:" . PHP_VERSION;
fastcgi_finish_request();
usleep(50000);
