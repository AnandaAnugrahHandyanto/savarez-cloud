<?php

/*
 * WARNING
 *
 * This file gets modified by automatic processes and all lines that are not
 * active code (ie. comments) are lost during that process.
 *
 * If you want to document things with comments or use constants add your settings
 * in a '<NAME>.config.php' file which will be included and rendered into this file.
 *
 * Example:
 *   <?php
 *   $CONFIG = [];
 *
 * See also: https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html#multiple-merged-configuration-files
 */
$CONFIG = array (
  'instanceid' => 'ocgx5isrygy9',
  'passwordsalt' => 'PIDa04J30Ng+PmfWzgs3kqNfUZ0Jil',
  'secret' => '7wVH75nrLQnWpBxayFI/ymj6/xt8FYY0u2uVQAUDbm01fvu5',
  'trusted_domains' => 
  array (
    0 => '192.168.1.14',
    1 => 'cloud.anandaanugrah.me',
  ),
  'datadirectory' => '/srv/nextcloud-data',
  'dbtype' => 'mysql',
  'version' => '34.0.1.2',
  'overwrite.cli.url' => 'https://cloud.anandaanugrah.me',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'nextcloud',
  'dbpassword' => 'apadahlu',
  'installed' => true,
  'overwriteprotocol' => 'https',
  'maintenance' => false,
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
    'host' => '127.0.0.1',
    'port' => 6379,
  ),
  'maintenance_window_start' => 2,
  'default_phone_region' => 'ID',
);
